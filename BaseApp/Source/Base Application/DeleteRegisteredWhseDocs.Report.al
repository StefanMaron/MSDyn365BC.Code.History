report 5755 "Delete Registered Whse. Docs."
{
    Caption = 'Delete Registered Whse. Docs.';
    ProcessingOnly = true;
    Permissions = TableData "Registered Whse. Activity Hdr." = rimd;

    dataset
    {
        dataitem("Registered Whse. Activity Hdr."; "Registered Whse. Activity Hdr.")
        {
            DataItemTableView = SORTING(Type, "No.");
            RequestFilterFields = Type, "No.";
            RequestFilterHeading = 'Registered Whse. Docs.';

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, Type);
                Window.Update(2, "No.");

                Delete(true);
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text000 +
                  Text001 +
                  Text002);
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
        Text000: Label 'Processing registered documents...\\';
        Text001: Label 'Type             #1##########\';
        Text002: Label 'No.              #2##########';
        Window: Dialog;
}

