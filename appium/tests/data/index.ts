export const CommonData = {
    account: {
        email: 'e2e.enterprise.test@flowcrypt.com',
        password: process.env.ACCOUNT_PASSWORD,
        passPhrase: 'London is the capital of Great Britain'
    },
    sender: {
        email: 'dmitry@flowcrypt.com',
    },
    contact: {
        email: 'dmitry@flowcrypt.com',
        name: 'Dima'
    },
    bundleId: {
        id: 'com.flowcrypt.as.ios.debug',
    },
    encryptedEmail: {
        subject: 'encrypted email',
        message: 'test test',
    },
    encryptedEmailWithAttachment: {
        subject: 'email with attachment',
        message:'this email contains attachment',
        attachmentName: 'image.png'
    },
    simpleEmail: {
        subject: 'Test 1',
        message: 'Test email',
    },
};
