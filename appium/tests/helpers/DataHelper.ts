import moment from 'moment';

class DataHelper {
  static uniqueValue() {
    return Math.random().toString(36).substring(2);
  }
  static convertDateToMSec = (date: string) => {
    return Date.parse(moment(date.replace('at', '')).toISOString());
  };
}

export default DataHelper;
