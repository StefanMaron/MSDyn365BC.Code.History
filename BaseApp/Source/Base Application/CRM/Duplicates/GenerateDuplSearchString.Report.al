namespace Microsoft.CRM.Duplicates;

using Microsoft.CRM.Contact;

report 5187 "Generate Dupl. Search String"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Generate Duplicate Search String';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Contact; Contact)
        {
            DataItemTableView = where(Type = const(Company));
            RequestFilterFields = "No.", "Company No.", "Last Date Modified", "External ID";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1);
                DuplMgt.MakeContIndex(Contact);
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000 +
                  Text001, "No.");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        DuplMgt: Codeunit DuplicateManagement;
        Window: Dialog;

        Text000: Label 'Processing contacts...\\';
        Text001: Label 'Contact No.     #1##########';
}

