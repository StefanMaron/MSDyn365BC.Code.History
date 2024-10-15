page 1628 "Office No Vendor Dlg"
{
    Caption = 'Create vendor record?';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = Contact;

    layout
    {
        area(content)
        {
            field("STRSUBSTNO(VendDialogLbl,Name)"; StrSubstNo(VendDialogLbl, Name))
            {
                ApplicationArea = All;
                ShowCaption = false;
            }
            group(Control2)
            {
                ShowCaption = false;
                field(CreateVend; StrSubstNo(CreateVendLbl, Name))
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a new vendor for the contact.';

                    trigger OnDrillDown()
                    var
                        VendorTemplateCode: Code[10];
                    begin
                        CreateVendor(VendorTemplateCode);
                        CurrPage.Close;
                    end;
                }
                field(ViewVendList; ViewVendListLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a list of vendors that are available in your company.';

                    trigger OnDrillDown()
                    var
                        Vendor: Record Vendor;
                    begin
                        PAGE.Run(PAGE::"Vendor List", Vendor);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        VendDialogLbl: Label 'Cannot find an existing vendor that matches the contact %1. Do you want to create a new vendor based on this contact?', Comment = '%1 = Contact name';
        CreateVendLbl: Label 'Create a vendor record for %1', Comment = '%1 = Contact name';
        ViewVendListLbl: Label 'View vendor list';
}

