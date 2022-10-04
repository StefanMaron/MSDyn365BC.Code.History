table 5913 Loaner
{
    Caption = 'Loaner';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Loaner List";
    LookupPageID = "Loaner List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    ServMgtSetup.Get();
                    NoSeriesMgt.TestManual(ServMgtSetup."Loaner Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(5; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF ("Item No." = CONST('<>''')) "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."))
            ELSE
            "Unit of Measure";
        }
        field(6; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." <> '' then begin
                    Item.Get("Item No.");
                    Description := Item.Description;
                    "Description 2" := Item."Description 2";
                end else begin
                    Description := '';
                    "Description 2" := '';
                end;
            end;
        }
        field(7; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(8; Comment; Boolean)
        {
            CalcFormula = Exist ("Service Comment Line" WHERE("Table Name" = CONST(Loaner),
                                                              "Table Subtype" = CONST("0"),
                                                              "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(11; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(12; "Document No."; Code[20])
        {
            CalcFormula = Lookup ("Loaner Entry"."Document No." WHERE("Loaner No." = FIELD("No."),
                                                                      Lent = CONST(true)));
            Caption = 'Document No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Lent; Boolean)
        {
            CalcFormula = Exist ("Loaner Entry" WHERE("Loaner No." = FIELD("No."),
                                                      Lent = CONST(true)));
            Caption = 'Lent';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(15; "Document Type"; Enum "Service Loaner Document Type")
        {
            CalcFormula = Lookup ("Loaner Entry"."Document Type" WHERE("Loaner No." = FIELD("No."),
                                                                       Lent = CONST(true)));
            Caption = 'Document Type';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Description)
        {
        }
        key(Key3; "Item No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Item No.")
        {
        }
    }

    trigger OnDelete()
    var
        ServCommentLine: Record "Service Comment Line";
    begin
        CalcFields(Lent, "Document No.");

        if Lent then
            Error(Text000);

        if not Blocked then
            Error(Text001, TableCaption(), FieldCaption(Blocked));

        Clear(LoanerEntry);
        LoanerEntry.SetCurrentKey("Loaner No.");
        LoanerEntry.SetRange("Loaner No.", "No.");
        LoanerEntry.DeleteAll();

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::Loaner);
        ServCommentLine.SetRange("Table Subtype", 0);
        ServCommentLine.SetRange("No.", "No.");
        ServCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            ServMgtSetup.Get();
            ServMgtSetup.TestField("Loaner Nos.");
            NoSeriesMgt.InitSeries(ServMgtSetup."Loaner Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    var
        Text000: Label 'You cannot delete a loaner that is lent.';
        Text001: Label 'You can only delete a %1 that is %2.';
        ServMgtSetup: Record "Service Mgt. Setup";
        Item: Record Item;
        Loaner: Record Loaner;
        LoanerEntry: Record "Loaner Entry";
        NoSeriesMgt: Codeunit NoSeriesManagement;

    procedure AssistEdit(OldLoaner: Record Loaner): Boolean
    begin
        with Loaner do begin
            Loaner := Rec;
            ServMgtSetup.Get();
            ServMgtSetup.TestField("Loaner Nos.");
            if NoSeriesMgt.SelectSeries(ServMgtSetup."Loaner Nos.", OldLoaner."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := Loaner;
                exit(true);
            end;
        end;
    end;
}

