export const CommonData = {
    account: {
        email: 'e2e.enterprise.test@flowcrypt.com',
        password: process.env.ACCOUNT_PASSWORD,
        passPhrase: 'London blueBARREY capi'
    },
    sender: {
        email: 'dmitry@flowcrypt.com',
    },
    contact: {
        email: 'dmitry@flowcrypt.com',
        name: 'Dima'
    },
    secondContact: {
        email: 'demo@flowcrypt.com',
        name: 'Demo'
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
