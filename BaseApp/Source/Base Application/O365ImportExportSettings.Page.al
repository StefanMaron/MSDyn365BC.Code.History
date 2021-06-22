page 2134 "O365 Import Export Settings"
{
    Caption = 'Export and Synchronization';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "O365 Settings Menu";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Title; Title)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies a description of the import export setting.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    OpenPage;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InsertMenuItems;
    end;

    var
        ExportTitleLbl: Label 'Export invoices';
        ExportDescriptionLbl: Label 'Export and send invoices.';
        ImportCustomersTieleLbl: Label 'Import customers';
        ImportCustomersDesriptionLbl: Label 'Import customers from Excel';
        ImportItemsTieleLbl: Label 'Import prices';
        ImportItemsDesriptionLbl: Label 'Import prices from Excel';

    local procedure InsertMenuItems()
    var
        DummyCustomer: Record Customer;
        DummyItem: Record Item;
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        InsertPageMenuItem(PAGE::"O365 Export Invoices", ExportTitleLbl, ExportDescriptionLbl);
        OnInsertMenuItems(Rec);

        if ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::Phone then begin
            InsertPageWithParameterMenuItem(
              PAGE::"O365 Import from Excel Wizard",
              DummyCustomer.TableName,
              ImportCustomersTieleLbl,
              ImportCustomersDesriptionLbl);
            InsertPageWithParameterMenuItem(
              PAGE::"O365 Import from Excel Wizard",
              DummyItem.TableName,
              ImportItemsTieleLbl,
              ImportItemsDesriptionLbl);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertMenuItems(var O365SettingsMenu: Record "O365 Settings Menu")
    begin
    end;
}

