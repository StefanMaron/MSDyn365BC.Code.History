page 6406 "Gen. Journal Batch Entity"
{
    Caption = 'workflowGenJournalBatches', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = Id;
    PageType = List;
    SourceTable = "Gen. Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(journalTemplateName; "Journal Template Name")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Template Name', Locked = true;
                }
                field(name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name', Locked = true;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                }
                field(reasonCode; "Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Reason Code', Locked = true;
                }
                field(balAccountType; "Bal. Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account Type', Locked = true;
                }
                field(balAccountNumber; "Bal. Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account No.', Locked = true;
                }
                field(numberSeries; "No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'No. Series', Locked = true;
                }
                field(postingNumberSeries; "Posting No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No. Series', Locked = true;
                }
                field(copyVatSetupToJnlLines; "Copy VAT Setup to Jnl. Lines")
                {
                    ApplicationArea = All;
                    Caption = 'Copy VAT Setup to Jnl. Lines', Locked = true;
                }
                field(allowVatDifference; "Allow VAT Difference")
                {
                    ApplicationArea = All;
                    Caption = 'Allow VAT Difference', Locked = true;
                }
                field(allowPaymentExport; "Allow Payment Export")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Payment Export', Locked = true;
                }
                field(bankStatementImportFormat; "Bank Statement Import Format")
                {
                    ApplicationArea = All;
                    Caption = 'Bank Statement Import Format', Locked = true;
                }
                field(templateType; "Template Type")
                {
                    ApplicationArea = All;
                    Caption = 'Template Type', Locked = true;
                }
                field(recurring; Recurring)
                {
                    ApplicationArea = All;
                    Caption = 'Recurring', Locked = true;
                }
                field(suggestBalancingAmount; "Suggest Balancing Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Suggest Balancing Amount', Locked = true;
                }
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field(lastModifiedDatetime; "Last Modified DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modified DateTime', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}

