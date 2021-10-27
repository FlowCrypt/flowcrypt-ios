export const CommonData = {
    account: {
        email: process.env.ACCOUNT_EMAIL,
        password: process.env.ACCOUNT_PASSWORD,
        passPhrase: process.env.PASS_PHRASE
    },
    recipient: {
        email: process.env.RECIPIENT_EMAIL,
        name: process.env.RECIPIENT_NAME
    },
    sender: {
        email: process.env.SENDER_EMAIL,
    },
    bundleId: {
        id: process.env.BUNDLE_ID
    }
};
