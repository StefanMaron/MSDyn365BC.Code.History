#if not CLEAN21
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
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Title; Rec.Title)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Open';
                Image = DocumentEdit;
                Scope = Repeater;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    Rec.OpenPage();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        InsertMenuItems();
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
        Rec.InsertPageMenuItem(PAGE::"O365 Export Invoices", ExportTitleLbl, ExportDescriptionLbl);
        OnInsertMenuItems(Rec);

        if ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::Phone then begin
            Rec.InsertPageWithParameterMenuItem(
              PAGE::"O365 Import from Excel Wizard",
              DummyCustomer.TableName,
              ImportCustomersTieleLbl,
              ImportCustomersDesriptionLbl);
            Rec.InsertPageWithParameterMenuItem(
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
#endif
