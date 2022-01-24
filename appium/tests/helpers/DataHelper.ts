import moment from "moment";

class DataHelper {
  static uniqueValue() {
    return Math.random().toString(36).substring(2);
  }
  static convertDateToMSec = async (date: string ) => {
     return await Date.parse(moment(date.replace('at', '')).toISOString())
  }
}

export default DataHelper;
