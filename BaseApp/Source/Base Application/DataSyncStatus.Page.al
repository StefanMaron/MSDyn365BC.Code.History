page 6250 "Data Sync Status"
{
    ApplicationArea = All;
    Caption = 'Data Sync Status';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            part("Data Migration Status"; "Data Migration Overview")
            {
                ApplicationArea = All;
                Visible = ShowMigrationErrors;
            }
            part("Migration Errors"; "Data Migration Error")
            {
                ApplicationArea = All;
                Caption = 'Migration Errors';
                SubPageView = WHERE("Destination Table ID" = FILTER(> 0));
                Visible = ShowMigrationErrors;
            }
            part("Posting Errors"; "Data Migration Error")
            {
                ApplicationArea = All;
                Caption = 'Posting Errors';
                SubPageView = WHERE("Destination Table ID" = FILTER(= 0));
                Visible = NOT ShowMigrationErrors;
            }
        }
    }

    actions
    {
    }

    var
        GenJournalLine: Record "Gen. Journal Line";
        GPBatchTxt: Label 'GP*', Locked = true;
        CustomerBatchTxt: Label 'GPCUST', Locked = true;
        VendorBatchTxt: Label 'GPVEND', Locked = true;
        JnlTemplateNameTxt: Label 'GENERAL', Locked = true;
        ShowMigrationErrors: Boolean;

    local procedure PostingErrors(JournalBatchName: Text)
    begin
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", JnlTemplateNameTxt);
        GenJournalLine.SetFilter("Journal Batch Name", JournalBatchName);
        if GenJournalLine.FindSet() then
            REPORT.Run(REPORT::"Auto Posting Errors", false, false, GenJournalLine);
    end;

    procedure ParsePosting()
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.Reset();
        if DataMigrationStatus.FindFirst() then begin
            PostingErrors(GPBatchTxt);
            PostingErrors(VendorBatchTxt);
            PostingErrors(CustomerBatchTxt);
        end;
    end;

    procedure SetMigrationVisibility(IsMigration: Boolean)
    begin
        ShowMigrationErrors := IsMigration;
    end;
}

