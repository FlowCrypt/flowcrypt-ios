let faker = require('faker');

class DataHelper {

    static uniqueValue() {
        return faker.random.uuid().split('-')[0];
    }
}

export default DataHelper;
