page 609 "IC Partner Card"
{
    Caption = 'Intercompany Partner';
    PageType = Card;
    SourceTable = "IC Partner";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the intercompany partner code.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the name of the intercompany partner.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                }
                field("Inbox Type"; "Inbox Type")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Transfer Type';
                    ToolTip = 'Specifies what type of inbox the intercompany partner has. File Location. You send the partner a file containing intercompany transactions. Database: The partner is set up as another company in the same database. Email: You send the partner transactions by email.';

                    trigger OnValidate()
                    begin
                        SetInboxDetailsCaption;
                    end;
                }
                field("Inbox Details"; "Inbox Details")
                {
                    ApplicationArea = Intercompany;
                    CaptionClass = TransferTypeLbl;
                    Editable = EnableInboxDetails;
                    Enabled = EnableInboxDetails;
                    ToolTip = 'Specifies the details of the intercompany partner''s inbox.';
                }
                field("Auto. Accept Transactions"; "Auto. Accept Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Auto. Accept Transactions';
                    Editable = "Inbox Type" = "Inbox Type"::Database;
                    Enabled = "Inbox Type" = "Inbox Type"::Database;
                    ToolTip = 'Specifies that transactions from this intercompany partner are automatically accepted.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
            group("Sales Transaction")
            {
                Caption = 'Sales Transaction';
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the customer number that this intercompany partner is linked to.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                        PropagateCustomerICPartner(xRec."Customer No.", "Customer No.", Code);
                        Find;
                    end;
                }
                field("Receivables Account"; "Receivables Account")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the general ledger account to use when you post receivables from customers in this posting group.';
                }
                field("Outbound Sales Item No. Type"; "Outbound Sales Item No. Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies what type of item number is entered in the IC Partner Reference field for items on purchase lines that you send to this IC partner.';
                }
            }
            group("Purchase Transaction")
            {
                Caption = 'Purchase Transaction';
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the vendor number that this intercompany partner is linked to.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                        PropagateVendorICPartner(xRec."Vendor No.", "Vendor No.", Code);
                        Find;
                    end;
                }
                field("Payables Account"; "Payables Account")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the general ledger account to use when you post payables due to vendors in this posting group.';
                }
                field("Outbound Purch. Item No. Type"; "Outbound Purch. Item No. Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies what type of item number is entered in the IC Partner Reference field for items on purchase lines that you send to this IC partner.';
                }
                field("Cost Distribution in LCY"; "Cost Distribution in LCY")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies whether costs are allocated in local currency to one or several IC partners.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("IC &Partner")
            {
                Caption = 'IC &Partner';
                Image = ICPartner;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(413),
                                  "No." = FIELD(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to intercompany transactions to distribute costs and analyze transaction history.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetInboxDetailsCaption;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetInboxDetailsCaption;
    end;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        TransferTypeLbl: Text;
        CompanyNameTransferTypeTxt: Label 'Company Name';
        FolderPathTransferTypeTxt: Label 'Folder Path';
        EmailAddressTransferTypeTxt: Label 'Email Address';
        EnableInboxDetails: Boolean;

    local procedure SetInboxDetailsCaption()
    begin
        EnableInboxDetails :=
          ("Inbox Type" <> "Inbox Type"::"No IC Transfer") and
          not (("Inbox Type" = "Inbox Type"::"File Location") and EnvironmentInfo.IsSaaS);
        case "Inbox Type" of
            "Inbox Type"::Database:
                TransferTypeLbl := CompanyNameTransferTypeTxt;
            "Inbox Type"::"File Location":
                TransferTypeLbl := FolderPathTransferTypeTxt;
            "Inbox Type"::Email:
                TransferTypeLbl := EmailAddressTransferTypeTxt;
        end;
    end;
}

