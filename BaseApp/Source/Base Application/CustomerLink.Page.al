page 5135 "Customer Link"
{
    Caption = 'Customer Link';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Contact Business Relation";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the number assigned to the contact in the Customer, Vendor, or Bank Account table. This field is only valid for contacts recorded as customer, vendor or bank accounts.';
                }
                field(CurrMasterFields; CurrMasterFields)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Current Master Fields';
                    OptionCaption = 'Contact,Customer';
                    ToolTip = 'Specifies which fields should be used to prioritize in case there is conflicting information in fields common to the contact card and the bank account card.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if ("No." <> '') and (CloseAction = ACTION::LookupOK) then begin
            ContBusRel := Rec;
            ContBusRel.Insert(true);

            case CurrMasterFields of
                CurrMasterFields::Contact:
                    begin
                        Cont.Get(ContBusRel."Contact No.");
                        UpdateCustVendBank.UpdateCustomer(Cont, ContBusRel);
                    end;
                CurrMasterFields::Customer:
                    begin
                        Cust.Get(ContBusRel."No.");
                        UpdateContFromCust.OnModify(Cust);
                    end;
            end;
        end;
    end;

    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        Cust: Record Customer;
        UpdateCustVendBank: Codeunit "CustVendBank-Update";
        UpdateContFromCust: Codeunit "CustCont-Update";
        CurrMasterFields: Option Contact,Customer;
}

