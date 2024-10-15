table 11796 "User Setup Line"
{
    Caption = 'User Setup Line (Obsolete)';
    DataCaptionFields = "User ID", Type;
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '21.0';

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
            TableRelation = if (Type = const("Location (quantity increase)")) Location
            else
            if (Type = const("Location (quantity decrease)")) Location
            else
            if (Type = const("Release Location (quantity increase)")) Location
            else
            if (Type = const("Release Location (quantity decrease)")) Location
            else
            if (Type = const("Bank Account")) "Bank Account"
            else
            if (Type = const("Paym. Order")) "Bank Account"
            else
            if (Type = const("Bank Stmt")) "Bank Account"
            else
            if (Type = const("General Journal")) "Gen. Journal Template"
            else
            if (Type = const("Item Journal")) "Item Journal Template"
            else
            if (Type = const("Resource Journal")) "Res. Journal Template"
            else
            if (Type = const("Job Journal")) "Job Journal Template"
            else
            if (Type = const("Intrastat Journal")) "Intrastat Jnl. Template"
            else
            if (Type = const("FA Journal")) "FA Journal Template"
            else
            if (Type = const("Insurance Journal")) "Insurance Journal Template"
            else
            if (Type = const("FA Reclass. Journal")) "FA Reclass. Journal Template"
            else
            if (Type = const("Req. Worksheet")) "Req. Wksh. Template"
            else
            if (Type = const("VAT Statement")) "VAT Statement Template"
            else
            if (Type = const("Whse. Journal")) "Warehouse Journal Template"
            else
            if (Type = const("Whse. Worksheet")) "Whse. Worksheet Template";
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