page 1625 "Office Contact Associations"
{
    CaptionML = ENU = 'Which contact is associated to the email sender?';
    Editable = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Office Contact Details";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Associated Table"; Rec."Associated Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table that is associated with the contact, such as Customer, Vendor, Bank Account, or Company.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the contact.';
                    Style = Strong;
                }
                field(Company; Company)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company';
                    ToolTip = 'Specifies the company of the contact.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the associated Office contact.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the contact, such as company or contact person.';
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Office contact.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Customer/Vendor")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'C&ustomer/Vendor';
                Image = ContactReference;
                ShortCutKey = 'Return';
                ToolTip = 'View the related customer or vendor account that is associated with the current record.';

                trigger OnAction()
                var
                    Contact: Record Contact;
                    TempOfficeAddinContext: Record "Office Add-in Context" temporary;
                    OfficeContactHandler: Codeunit "Office Contact Handler";
                    OfficeMgt: Codeunit "Office Management";
                begin
                    if Company <> CompanyName() then begin
                        OfficeMgt.StoreValue('ContactNo', "Contact No.");
                        OfficeMgt.ChangeCompany(Company);
                        CurrPage.Close();
                        exit;
                    end;

                    OfficeMgt.GetContext(TempOfficeAddinContext);
                    case "Associated Table" of
                        "Associated Table"::" ":
                            if Contact.Get("Contact No.") then
                                Page.Run(Page::"Contact Card", Contact);
                        "Associated Table"::Company,
                        "Associated Table"::"Bank Account":
                            if Contact.Get("Contact No.") then
                                Page.Run(Page::"Contact Card", Contact);
                        else
                            OfficeContactHandler.ShowCustomerVendor(TempOfficeAddinContext, Contact, "Associated Table", "No.");
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Related Information', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Customer/Vendor_Promoted"; "Customer/Vendor")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetName();
    end;

    var
        Name: Text[100];

    local procedure GetName()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case "Associated Table" of
            "Associated Table"::Customer:
                if Customer.Get("No.") then
                    Name := Customer.Name;
            "Associated Table"::Vendor:
                if Vendor.Get("No.") then
                    Name := Vendor.Name;
            "Associated Table"::Company:
                if Contact.Get("No.") then
                    Name := Contact."Company Name";
            else
                Clear(Name);
        end;
    end;
}

