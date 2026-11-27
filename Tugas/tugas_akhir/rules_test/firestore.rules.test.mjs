import { after, before, beforeEach, describe, it } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'creaflow-rules-test',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

async function seedWorkspaceWithPmAndMember() {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'workspaces/ws-1'), {
      workspaceName: 'Tim Mobile',
      description: null,
      inviteCode: 'ABCD1234',
      status: 'active',
      createdBy: 'pm-1',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await setDoc(doc(db, 'workspaces/ws-1/members/pm-1'), {
      workspaceId: 'ws-1',
      userId: 'pm-1',
      role: 'pm',
      status: 'active',
      joinedAt: serverTimestamp(),
      removedAt: null,
    });
    await setDoc(doc(db, 'workspaces/ws-1/members/mem-1'), {
      workspaceId: 'ws-1',
      userId: 'mem-1',
      role: 'member',
      status: 'active',
      joinedAt: serverTimestamp(),
      removedAt: null,
    });
    await setDoc(doc(db, 'inviteCodes/ABCD1234'), {
      workspaceId: 'ws-1',
      createdBy: 'pm-1',
      createdAt: serverTimestamp(),
    });
  });
}

describe('Firestore Security Rules', () => {
  it('users: owner can create/update profile, list is denied, email immutable', async () => {
    const aliceDb = testEnv
      .authenticatedContext('alice', { email: 'alice@example.com' })
      .firestore();
    const bobDb = testEnv
      .authenticatedContext('bob', { email: 'bob@example.com' })
      .firestore();

    await assertSucceeds(
      setDoc(doc(aliceDb, 'users/alice'), {
        fullName: 'Alice',
        email: 'alice@example.com',
        profilePicture: null,
        phoneNumber: null,
        createdAt: serverTimestamp(),
      }),
    );

    // Non-owner cannot create or update Alice's profile
    await assertFails(
      setDoc(doc(bobDb, 'users/alice'), {
        fullName: 'Hacked',
        email: 'bob@example.com',
        profilePicture: null,
        phoneNumber: null,
        createdAt: serverTimestamp(),
      }),
    );

    // Listing users collection is denied
    await assertFails(getDocs(collection(aliceDb, 'users')));

    // Owner can update fullName, but cannot change email
    await assertSucceeds(
      updateDoc(doc(aliceDb, 'users/alice'), { fullName: 'Alice Updated' }),
    );
    await assertFails(
      updateDoc(doc(aliceDb, 'users/alice'), { email: 'new@example.com' }),
    );
  });

  it('workspaces & joinRequests: PM creates workspace, outsider requests join, PM approves', async () => {
    const pmDb = testEnv.authenticatedContext('pm-1').firestore();
    const outsiderDb = testEnv.authenticatedContext('outsider').firestore();

    // Atomic workspace creation batch
    const batch = writeBatch(pmDb);
    batch.set(doc(pmDb, 'workspaces/ws-new'), {
      workspaceName: 'CreaFlow',
      description: null,
      inviteCode: 'XYZ12345',
      status: 'active',
      createdBy: 'pm-1',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    batch.set(doc(pmDb, 'workspaces/ws-new/members/pm-1'), {
      workspaceId: 'ws-new',
      userId: 'pm-1',
      role: 'pm',
      status: 'active',
      joinedAt: serverTimestamp(),
      removedAt: null,
    });
    batch.set(doc(pmDb, 'inviteCodes/XYZ12345'), {
      workspaceId: 'ws-new',
      createdBy: 'pm-1',
      createdAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());

    // Outsider cannot read workspace
    await assertFails(getDoc(doc(outsiderDb, 'workspaces/ws-new')));

    // Outsider can submit join request
    await assertSucceeds(
      setDoc(doc(outsiderDb, 'workspaces/ws-new/joinRequests/outsider'), {
        workspaceId: 'ws-new',
        userId: 'outsider',
        status: 'pending',
        requestedAt: serverTimestamp(),
        reviewedAt: null,
        reviewedBy: null,
      }),
    );

    // Outsider cannot self-approve; PM can approve
    await assertFails(
      updateDoc(doc(outsiderDb, 'workspaces/ws-new/joinRequests/outsider'), {
        status: 'approved',
        reviewedAt: serverTimestamp(),
        reviewedBy: 'outsider',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(pmDb, 'workspaces/ws-new/joinRequests/outsider'), {
        status: 'approved',
        reviewedAt: serverTimestamp(),
        reviewedBy: 'pm-1',
      }),
    );
  });

  it('tasks: PM creates task, Option A status transitions enforced', async () => {
    await seedWorkspaceWithPmAndMember();
    const pmDb = testEnv.authenticatedContext('pm-1').firestore();
    const memDb = testEnv.authenticatedContext('mem-1').firestore();

    // Member cannot create task
    await assertFails(
      setDoc(doc(memDb, 'workspaces/ws-1/tasks/t1'), {
        workspaceId: 'ws-1',
        picMemberId: 'mem-1',
        createdBy: 'mem-1',
        title: 'Illegal',
        description: null,
        startDate: null,
        deadline: null,
        priority: 'medium',
        status: 'todo',
        archivedAt: null,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    // PM creates task
    await assertSucceeds(
      setDoc(doc(pmDb, 'workspaces/ws-1/tasks/t1'), {
        workspaceId: 'ws-1',
        picMemberId: 'mem-1',
        createdBy: 'pm-1',
        title: 'Build Auth',
        description: null,
        startDate: null,
        deadline: null,
        priority: 'high',
        status: 'todo',
        archivedAt: null,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    // Illegal skip (todo -> done) denied even for PM
    await assertFails(
      updateDoc(doc(pmDb, 'workspaces/ws-1/tasks/t1'), {
        status: 'done',
        updatedAt: serverTimestamp(),
      }),
    );

    // PIC transitions todo -> in_progress -> in_review
    await assertSucceeds(
      updateDoc(doc(memDb, 'workspaces/ws-1/tasks/t1'), {
        status: 'in_progress',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      updateDoc(doc(memDb, 'workspaces/ws-1/tasks/t1'), {
        status: 'in_review',
        updatedAt: serverTimestamp(),
      }),
    );

    // PIC cannot approve (in_review -> done)
    await assertFails(
      updateDoc(doc(memDb, 'workspaces/ws-1/tasks/t1'), {
        status: 'done',
        updatedAt: serverTimestamp(),
      }),
    );

    // PM can approve (in_review -> done)
    await assertSucceeds(
      updateDoc(doc(pmDb, 'workspaces/ws-1/tasks/t1'), {
        status: 'done',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('collaboration & notifications: member comments/attachments validated, notifications private', async () => {
    await seedWorkspaceWithPmAndMember();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'workspaces/ws-1/tasks/t1'), {
        workspaceId: 'ws-1',
        picMemberId: 'mem-1',
        createdBy: 'pm-1',
        title: 'Task',
        description: null,
        startDate: null,
        deadline: null,
        priority: 'medium',
        status: 'todo',
        archivedAt: null,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      await setDoc(doc(db, 'users/mem-1/notifications/n1'), {
        userId: 'mem-1',
        workspaceId: 'ws-1',
        taskId: 't1',
        type: 'task_assigned',
        message: 'Assigned',
        isRead: false,
        createdAt: serverTimestamp(),
      });
    });

    const memDb = testEnv.authenticatedContext('mem-1').firestore();
    const outsiderDb = testEnv.authenticatedContext('outsider').firestore();

    await assertSucceeds(
      setDoc(doc(memDb, 'workspaces/ws-1/tasks/t1/comments/c1'), {
        taskId: 't1',
        userId: 'mem-1',
        commentText: 'Siap dikerjakan',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(outsiderDb, 'workspaces/ws-1/tasks/t1/comments/c2'), {
        taskId: 't1',
        userId: 'outsider',
        commentText: 'Spam',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );

    // Valid https attachment succeeds, ftp:// fails
    await assertSucceeds(
      setDoc(doc(memDb, 'workspaces/ws-1/tasks/t1/attachments/a1'), {
        taskId: 't1',
        uploadedBy: 'mem-1',
        fileUrl: 'https://res.cloudinary.com/demo/image/upload/v1/test.png',
        uploadedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(memDb, 'workspaces/ws-1/tasks/t1/attachments/a2'), {
        taskId: 't1',
        uploadedBy: 'mem-1',
        fileUrl: 'ftp://invalid.example.com/file.png',
        uploadedAt: serverTimestamp(),
      }),
    );

    // Notification privacy
    await assertSucceeds(getDoc(doc(memDb, 'users/mem-1/notifications/n1')));
    await assertFails(
      getDoc(doc(outsiderDb, 'users/mem-1/notifications/n1')),
    );
    await assertSucceeds(
      updateDoc(doc(memDb, 'users/mem-1/notifications/n1'), { isRead: true }),
    );
  });
});
