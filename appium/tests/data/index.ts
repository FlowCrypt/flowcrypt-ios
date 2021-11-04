export const CommonData = {
    account: {
        email: process.env.ACCOUNT_EMAIL,
        password: process.env.ACCOUNT_PASSWORD,
        passPhrase: process.env.PASS_PHRASE,
        wrongPassPhrase: 'user is not able to see email'
    },
    sender: {
        email: process.env.SENDER_EMAIL,
    },
    contact: {
        email: 'dmitry@flowcrypt.com',
        name: 'Dima'
    },
    bundleId: {
        id: process.env.BUNDLE_ID
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
