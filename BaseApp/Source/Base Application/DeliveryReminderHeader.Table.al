table 5005270 "Delivery Reminder Header"
{
    Caption = 'Delivery Reminder Header';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Delivery Reminder List";
    LookupPageID = "Delivery Reminder List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                DeliveryReminderLine.Reset;
                DeliveryReminderLine.SetRange("Document No.", "No.");

                if (xRec."Vendor No." <> "Vendor No.") and
                   (xRec."Vendor No." <> '') and
                   DeliveryReminderLine.FindFirst
                then begin
                    if not Confirm(Text1140001, false) then begin
                        "Vendor No." := xRec."Vendor No.";
                        exit;
                    end;
                    DeliveryReminderLine.DeleteAll;
                end;

                GetVend("Vendor No.");
                Name := Vend.Name;
                "Name 2" := Vend."Name 2";
                Address := Vend.Address;
                "Address 2" := Vend."Address 2";
                City := Vend.City;
                "Post Code" := Vend."Post Code";
                County := Vend.County;
                "Country/Region Code" := Vend."Country/Region Code";
                Contact := Vend.Contact;
                "Language Code" := Vend."Language Code";
                "Reminder Terms Code" := Vend."Delivery Reminder Terms";
                Validate("Reminder Terms Code");
            end;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
        }
        field(9; County; Text[30])
        {
            Caption = 'County';
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(13; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(22; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(24; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            TableRelation = "Delivery Reminder Term";

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Reminder Terms Code") then
                    if Undo then begin
                        "Reminder Terms Code" := xRec."Reminder Terms Code";
                        exit;
                    end;
                if "Reminder Terms Code" <> '' then begin
                    DeliveryReminderTerms.Get("Reminder Terms Code");
                    Validate("Reminder Level");
                end;
            end;
        }
        field(27; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(28; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';

            trigger OnValidate()
            begin
                if ("Reminder Level" <> 0) and ("Reminder Terms Code" <> '') then begin
                    DeliveryReminderTerms.Get("Reminder Terms Code");
                    DeliveryReminderLevel.SetRange("Reminder Terms Code", "Reminder Terms Code");
                    DeliveryReminderLevel.SetRange("No.", 1, "Reminder Level");
                    if DeliveryReminderLevel.FindLast and ("Document Date" <> 0D) then
                        "Due Date" := CalcDate(DeliveryReminderLevel."Due Date Calculation", "Document Date");
                end;
            end;
        }
        field(29; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = Exist ("Delivery Reminder Comment Line" WHERE("Document Type" = CONST("Delivery Reminder"),
                                                                        "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(37; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(38; "Issuing No. Series"; Code[20])
        {
            Caption = 'Issuing No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                IsHandled: Boolean;
            begin
                with DeliveryReminderHeader do begin
                    DeliveryReminderHeader := Rec;
                    PurchSetup.Get;
                    IsHandled := false;
                    OnBeforeLookupIssuingNoSeries(Rec, IsHandled);
                    if not IsHandled then begin
                        PurchSetup.TestField("Delivery Reminder Nos.");
                        PurchSetup.TestField("Issued Delivery Reminder Nos.");
                        if NoSeriesMgt.LookupSeries(PurchSetup."Issued Delivery Reminder Nos.", "Issuing No. Series") then
                            Validate("Issuing No. Series");
                    end;
                    Rec := DeliveryReminderHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Issuing No. Series" <> '' then begin
                    PurchSetup.Get;
                    PurchSetup.TestField("Delivery Reminder Nos.");
                    PurchSetup.TestField("Issued Delivery Reminder Nos.");
                    NoSeriesMgt.TestSeries(PurchSetup."Issued Delivery Reminder Nos.", "Issuing No. Series");
                end;
                TestField("Issuing No.", '');
            end;
        }
        field(39; "Issuing No."; Code[20])
        {
            Caption = 'Issuing No.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Vendor No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name)
        {
        }
    }

    trigger OnDelete()
    begin
        LockTable;
        DeliveryReminderLine.Reset;
        DeliveryReminderLine.SetRange("Document No.", "No.");
        DeliveryReminderLine.DeleteAll;

        DeliveryReminderCommentLine.Reset;
        DeliveryReminderCommentLine.SetRange("Document Type", DeliveryReminderCommentLine."Document Type"::"Delivery Reminder");
        DeliveryReminderCommentLine.SetRange("No.", "No.");
        DeliveryReminderCommentLine.DeleteAll;
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        PurchSetup.Get;
        IsHandled := false;
        OnBeforeInsert(Rec, IsHandled);
        if not IsHandled then begin
            if "No." = '' then begin
                PurchSetup.TestField("Delivery Reminder Nos.");
                PurchSetup.TestField("Issued Delivery Reminder Nos.");
                NoSeriesMgt.InitSeries(
                  PurchSetup."Delivery Reminder Nos.", xRec."No. Series", "Posting Date",
                  "No.", "No. Series");
            end;
            "Posting Description" := StrSubstNo(Text1140000, "No.");
            if ("No. Series" <> '') and
               (PurchSetup."Delivery Reminder Nos." = PurchSetup."Issued Delivery Reminder Nos.")
            then
                "Issuing No. Series" := "No. Series"
            else
                NoSeriesMgt.SetDefaultSeries("Issuing No. Series", PurchSetup."Issued Delivery Reminder Nos.");
        end;
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate;
        "Document Date" := WorkDate;

        if GetFilter("Vendor No.") <> '' then
            if GetRangeMin("Vendor No.") = GetRangeMax("Vendor No.") then
                Validate("Vendor No.", GetRangeMin("Vendor No."));
    end;

    var
        Text1140000: Label 'Reminder %1';
        Text1140001: Label 'All entered Lines will be deleted?';
        Text1140002: Label 'This change will cause the existing lines to be deleted for this reminder.\\';
        Text1140003: Label 'Do you want to continue?';
        PurchSetup: Record "Purchases & Payables Setup";
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        DeliveryReminderTerms: Record "Delivery Reminder Term";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        DeliveryReminderCommentLine: Record "Delivery Reminder Comment Line";
        Vend: Record Vendor;
        NoSeriesMgt: Codeunit NoSeriesManagement;

    [Scope('OnPrem')]
    procedure AssistEdit(OldReminderHeader: Record "Delivery Reminder Header"): Boolean
    var
        IsHandled: Boolean;
    begin
        with DeliveryReminderHeader do begin
            DeliveryReminderHeader := Rec;
            PurchSetup.Get;
            IsHandled := false;
            OnBeforeAssistEdit(DeliveryReminderHeader, OldReminderHeader, IsHandled);
            if not IsHandled then begin
                PurchSetup.TestField("Delivery Reminder Nos.");
                PurchSetup.TestField("Issued Delivery Reminder Nos.");
                if NoSeriesMgt.SelectSeries(
                     PurchSetup."Delivery Reminder Nos.", OldReminderHeader."No. Series", "No. Series")
                then begin
                    PurchSetup.Get;
                    PurchSetup.TestField("Delivery Reminder Nos.");
                    PurchSetup.TestField("Issued Delivery Reminder Nos.");
                    NoSeriesMgt.SetSeries("No.");
                    Rec := DeliveryReminderHeader;
                    exit(true);
                end;
            end else
                exit(true);
        end;
    end;

    local procedure GetVend(VendNo: Code[20])
    begin
        if VendNo <> Vend."No." then
            Vend.Get(VendNo);
    end;

    local procedure Undo(): Boolean
    begin
        DeliveryReminderLine.SetRange("Document No.", "No.");
        if DeliveryReminderLine.FindFirst then begin
            Commit;
            if not
               Confirm(
                 Text1140002 +
                 Text1140003,
                 false)
            then
                exit(true);
            DeliveryReminderLine.DeleteAll;
            Modify
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var DeliveryReminderHeader: Record "Delivery Reminder Header"; OldDeliveryReminderHeader: Record "Delivery Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsert(var DeliveryReminderHeader: Record "Delivery Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupIssuingNoSeries(var DeliveryReminderHeader: Record "Delivery Reminder Header"; var IsHandled: Boolean)
    begin
    end;
}

