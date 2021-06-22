table 871 "Social Listening Search Topic"
{
    Caption = 'Social Listening Search Topic';

    fields
    {
        field(1; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Item,Vendor,Customer';
            OptionMembers = " ",Item,Vendor,Customer;
        }
        field(2; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST(Item)) Item;
        }
        field(3; "Search Topic"; Text[250])
        {
            Caption = 'Search Topic';

            trigger OnValidate()
            begin
                SocialListeningMgt.CheckURLPath("Search Topic", '&nodeid=');
                "Search Topic" := SocialListeningMgt.ConvertURLToID("Search Topic", '&nodeid=');
            end;
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Source No.");
    end;

    trigger OnRename()
    begin
        TestField("Source No.");
    end;

    var
        SocialListeningMgt: Codeunit "Social Listening Management";

    procedure FindSearchTopic(SourceType: Option; SourceNo: Code[20]): Boolean
    begin
        exit(Get(SourceType, SourceNo))
    end;

    procedure GetCaption(): Text
    var
        Cust: Record Customer;
        Item: Record Item;
        Vend: Record Vendor;
        Descr: Text[100];
    begin
        if "Source No." = '' then
            exit;

        case "Source Type" of
            "Source Type"::Customer:
                if Cust.Get("Source No.") then
                    Descr := Cust.Name;
            "Source Type"::Vendor:
                if Vend.Get("Source No.") then
                    Descr := Vend.Name;
            "Source Type"::Item:
                if Item.Get("Source No.") then
                    Descr := Item.Description;
        end;
        exit(StrSubstNo('%1 %2 %3 %4', "Source Type", "Source No.", Descr, "Search Topic"));
    end;
}

