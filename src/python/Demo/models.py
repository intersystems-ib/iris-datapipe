from DataPipe import Model
from dataclasses import dataclass
import json
import iris
import random

@dataclass
class A08(Model):

    msg_id: str = None
    patient_id: str = None
    name: str = None
    surname1: str = None
    surname2: str = None
    birth_date: str = None
    administrative_sex: str = None
    ssn: str = None

    def serialize(self):
        # convert this object to a json string
        # export all attributes except error_list and log_list
        export = {key: value for key, value in self.__dict__.items() if key not in ["error_list","log_list"]}
        return json.dumps(export, indent=4)

    def deserialize(self, json_str):
        # populate each attr of this object from a json string
        json_dict = json.loads(json_str)
        for key in json_dict:
            setattr(self, key, json_dict[key])

    def normalize(self):
        # normalize this object
        # convert administrative_sex to M to H and F to M and None to ""
        conversion = {"M":"H","F":"M",None:""}
        # apply conversion
        administrative_sex = self.administrative_sex.upper()
        self.administrative_sex = conversion.get(administrative_sex, "")
        # for demo purposes raise an exception if name is Alfred or James or Kevin
        if self.name.upper() in ["ALFRED","JAMES","KEVIN"]:
            raise Exception("Name is not valid")

    def validate(self):
        # create an iris.DataPipe.Data.ErrorInfo for each failed validation
        if self.administrative_sex is None or self.administrative_sex == "":
            self.add_error("VGEN","AdministrativeSex required")

        if self.birth_date is None or self.birth_date == "":
            self.add_error("V001","BirthDate required")
        else:
            year = int(self.birth_date[0:4])
            if year < 1930:
                self.add_error("V002","DOB must be greater than 1930")
            if year > 1983:
                self.add_error("W083","Warning! Older than 1983")
        # model is invalid if errors (not warnings) found
        for error in self.error_list:
            if "V" in error.Code[0]:
                raise Exception("Model is invalid")
        return self.error_list

    def operation(self, operation_instance):
        """
        Perform operation
        """
        self.add_log("Performing operation")
        # once on 10 times raise an exception
        if random.randint(1,10) == 10:
            raise Exception("Random exception")

        if isinstance(operation_instance, object):
            self.add_log("Operation instance is an object")
            msg = iris.cls('Ens.StringContainer')._New()
            msg.StringValue = "Call production component during RunOperation() "
            operation_instance.SendRequestAsync("Dummy",msg)

    def get_operation(self):
        if 'FIFO' in self.msg_id:
            return "FIFO A08 Operation"
        return "A08 Operation"
