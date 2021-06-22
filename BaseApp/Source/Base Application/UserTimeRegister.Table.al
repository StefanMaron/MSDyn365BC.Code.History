table 51 "User Time Register"
{
    Caption = 'User Time Register';
    LookupPageID = "User Time Registers";

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
        }
        field(3; Minutes; Decimal)
        {
            Caption = 'Minutes';
            DecimalPlaces = 0 : 0;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "User ID", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

