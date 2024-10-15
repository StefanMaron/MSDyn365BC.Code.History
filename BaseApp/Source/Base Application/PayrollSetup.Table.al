table 1660 "Payroll Setup"
{
    Caption = 'Payroll Setup';
    DrillDownPageID = "Incoming Documents Setup";
    LookupPageID = "Incoming Documents Setup";

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Primary Key';
        }
        field(2; "General Journal Template Name"; Code[10])
        {
            Caption = 'General Journal Template Name';
            TableRelation = "Gen. Journal Template" WHERE(Type = FILTER(General),
                                                           Recurring = CONST(false));

            trigger OnValidate()
            var
                GenJournalTemplate: Record "Gen. Journal Template";
                xGenJournalTemplate: Record "Gen. Journal Template";
            begin
                if "General Journal Template Name" = '' then begin
                    "General Journal Batch Name" := '';
                    exit;
                end;
                GenJournalTemplate.Get("General Journal Template Name");
                if not (GenJournalTemplate.Type in
                        [GenJournalTemplate.Type::General, GenJournalTemplate.Type::Purchases, GenJournalTemplate.Type::Payments,
                         GenJournalTemplate.Type::Sales, GenJournalTemplate.Type::"Cash Receipts"])
                then
                    Error(
                      TemplateTypeErr,
                      GenJournalTemplate.Type::General, GenJournalTemplate.Type::Purchases, GenJournalTemplate.Type::Payments,
                      GenJournalTemplate.Type::Sales, GenJournalTemplate.Type::"Cash Receipts");
                if xRec."General Journal Template Name" <> '' then
                    if xGenJournalTemplate.Get(xRec."General Journal Template Name") then;
                if GenJournalTemplate.Type <> xGenJournalTemplate.Type then
                    "General Journal Batch Name" := '';
            end;
        }
        field(3; "General Journal Batch Name"; Code[10])
        {
            Caption = 'General Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("General Journal Template Name"));

            trigger OnValidate()
            var
                GenJournalBatch: Record "Gen. Journal Batch";
            begin
                if "General Journal Batch Name" <> '' then
                    TestField("General Journal Template Name");
                GenJournalBatch.Get("General Journal Template Name", "General Journal Batch Name");
                GenJournalBatch.TestField(Recurring, false);
            end;
        }
        field(10; "User Name"; Code[50])
        {
            Caption = 'User Name';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Fetched: Boolean;
        TemplateTypeErr: Label 'Only General Journal Templates of type %1, %2, %3, %4, or %5 are allowed.', Comment = '%1..5 lists Type=General,Purchases,Payments,Sales,Cash Receipts';

    procedure Fetch()
    begin
        if Fetched then
            exit;
        Fetched := true;
        if not Get then
            Init;
    end;
}

