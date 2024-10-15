table 11796 "User Setup Line"
{
    Caption = 'User Setup Line';
    DataCaptionFields = "User ID", Type;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Location (quantity increase),Location (quantity decrease),Bank Account,General Journal,Item Journal,,Resource Journal,Job Journal,Intrastat Journal,FA Journal,Insurance Journal,FA Reclass. Journal,Req. Worksheet,VAT Statement,,,Whse. Journal,Whse. Worksheet,Paym. Order,Bank Stmt,Whse. Net Change Templates,Release Location (quantity increase),Release Location (quantity decrease)';
            OptionMembers = "Location (quantity increase)","Location (quantity decrease)","Bank Account","General Journal","Item Journal",,"Resource Journal","Job Journal","Intrastat Journal","FA Journal","Insurance Journal","FA Reclass. Journal","Req. Worksheet","VAT Statement",,,"Whse. Journal","Whse. Worksheet","Paym. Order","Bank Stmt","Whse. Net Change Templates","Release Location (quantity increase)","Release Location (quantity decrease)";
        }
        field(20; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(30; "Code / Name"; Code[20])
        {
            Caption = 'Code / Name';
            TableRelation = IF (Type = CONST("Location (quantity increase)")) Location
            ELSE
            IF (Type = CONST("Location (quantity decrease)")) Location
            ELSE
            IF (Type = CONST("Release Location (quantity increase)")) Location
            ELSE
            IF (Type = CONST("Release Location (quantity decrease)")) Location
            ELSE
            IF (Type = CONST("Bank Account")) "Bank Account"
            ELSE
            IF (Type = CONST("Paym. Order")) "Bank Account"
            ELSE
            IF (Type = CONST("Bank Stmt")) "Bank Account"
            ELSE
            IF (Type = CONST("General Journal")) "Gen. Journal Template"
            ELSE
            IF (Type = CONST("Item Journal")) "Item Journal Template"
            ELSE
            IF (Type = CONST("Resource Journal")) "Res. Journal Template"
            ELSE
            IF (Type = CONST("Job Journal")) "Job Journal Template"
            ELSE
            IF (Type = CONST("Intrastat Journal")) "Intrastat Jnl. Template"
            ELSE
            IF (Type = CONST("FA Journal")) "FA Journal Template"
            ELSE
            IF (Type = CONST("Insurance Journal")) "Insurance Journal Template"
            ELSE
            IF (Type = CONST("FA Reclass. Journal")) "FA Reclass. Journal Template"
            ELSE
            IF (Type = CONST("Req. Worksheet")) "Req. Wksh. Template"
            ELSE
            IF (Type = CONST("VAT Statement")) "VAT Statement Template"
            ELSE
            IF (Type = CONST("Whse. Journal")) "Warehouse Journal Template"
            ELSE
            IF (Type = CONST("Whse. Worksheet")) "Whse. Worksheet Template"
            ELSE
            IF (Type = CONST("Whse. Net Change Templates")) "Whse. Net Change Template";
        }
    }

    keys
    {
        key(Key1; "User ID", Type, "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

