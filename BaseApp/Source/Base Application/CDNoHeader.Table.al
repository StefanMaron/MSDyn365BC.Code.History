table 12407 "CD No. Header"
{
    Caption = 'CD No. Header';
    LookupPageID = "Customs Declaration List";

    fields
    {
        field(1; "No."; Code[30])
        {
            Caption = 'No.';
        }
        field(3; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                CDNoInfo.Reset();
                CDNoInfo.SetRange("CD Header No.", "No.");
                if not CDNoInfo.IsEmpty then
                    if Confirm(Text001, true) then
                        CDNoInfo.ModifyAll("Country/Region Code", "Country/Region of Origin Code");
            end;
        }
        field(4; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(5; "Declaration Date"; Date)
        {
            Caption = 'Declaration Date';
        }
        field(7; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Item';
            OptionMembers = " ",Customer,Vendor,Item;
        }
        field(8; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST(Item)) Item;

            trigger OnValidate()
            begin
                case "Source Type" of
                    "Source Type"::Customer:
                        begin
                            Cust.Get("Source No.");
                            Validate("Country/Region of Origin Code", Cust."Country/Region Code");
                        end;
                    "Source Type"::Vendor:
                        begin
                            Vend.Get("Source No.");
                            Validate("Country/Region of Origin Code", Vend."Country/Region Code");
                        end;
                end;
            end;
        }
        field(9; "Stockout Warning"; Boolean)
        {
            Caption = 'Stockout Warning';
            Description = 'Not used';

            trigger OnValidate()
            begin
                CDNoInfo.Reset();
                CDNoInfo.SetRange("CD Header No.", "No.");
                if not CDNoInfo.IsEmpty then
                    if Confirm(Text001, true) then
                        CDNoInfo.ModifyAll("Stockout Warning", "Stockout Warning");
            end;
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = Exist ("Purch. Comment Line" WHERE("Document Type" = CONST("Custom Declaration"),
                                                             "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Declaration Date", "Source Type", "Source No.", "Country/Region of Origin Code")
        {
        }
    }

    trigger OnDelete()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("CD No.");
        ItemLedgEntry.SetRange("CD No.", "No.");
        if ItemLedgEntry.FindFirst then
            Error(Text002, "No.");

        CDNoInfo.Reset();
        CDNoInfo.SetRange("CD Header No.", "No.");
        CDNoInfo.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", "Declaration Date", "No.", "No. Series");
        end;
    end;

    trigger OnRename()
    begin
        CDNoInfo.Reset();
        CDNoInfo.SetRange("CD Header No.", xRec."No.");
        if CDNoInfo.FindFirst then
            Error(Text000, xRec."No.");
    end;

    var
        CDNoInfo: Record "CD No. Information";
        Text000: Label 'You cannot rename Custom Declaration %1.';
        Text001: Label 'You have changed the header. Do you want to change lines?';
        Text002: Label 'You cannot delete Custom Declaration %1.';
        Vend: Record Vendor;
        Cust: Record Customer;
        InvtSetup: Record "Inventory Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;

    [Scope('OnPrem')]
    procedure AssistEdit(OldCDNoHeader: Record "CD No. Header"): Boolean
    begin
        InvtSetup.Get();
        TestNoSeries;
        if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldCDNoHeader."No. Series", "No. Series") then begin
            InvtSetup.Get();
            TestNoSeries;
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    local procedure TestNoSeries()
    begin
        InvtSetup.Get();
        InvtSetup.TestField("CD Header Nos.");
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        InvtSetup.Get();
        exit(InvtSetup."CD Header Nos.");
    end;
}

