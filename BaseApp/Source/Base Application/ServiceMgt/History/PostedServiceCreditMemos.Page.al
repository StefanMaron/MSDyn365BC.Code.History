namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;
using Microsoft.Service.Comment;
using Microsoft.Utilities;

page 5971 "Posted Service Credit Memos"
{
    ApplicationArea = Service;
    Caption = 'Posted Service Credit Memos';
    CardPageID = "Posted Service Credit Memo";
    Editable = false;
    PageType = List;
    SourceTable = "Service Cr.Memo Header";
    SourceTableView = sorting("Posting Date")
                      order(Descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer associated with the credit memo.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer to whom you shipped the service on the credit memo.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the currency code for the amounts on the credit memo.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the contact person at the customer company.';
                    Visible = false;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    Visible = false;
                }
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region code of the customer''s billing address.';
                    Visible = false;
                }
                field("Bill-to Contact"; Rec."Bill-to Contact")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the credit memo was posted.';
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the salesperson associated with the credit memo.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location, such as warehouse or distribution center, where the credit memo was registered.';
                    Visible = true;
                }
                field("Document Exchange Status"; Rec."Document Exchange Status")
                {
                    ApplicationArea = Service;
                    StyleExpr = DocExchStatusStyle;
                    ToolTip = 'Specifies the status of the document if you are using a document exchange service to send it as an electronic document. The status values are reported by the document exchange service.';
                    Visible = DocExchStatusVisible;

                    trigger OnDrillDown()
                    var
                        DocExchServDocStatus: Codeunit "Doc. Exch. Serv.- Doc. Status";
                    begin
                        DocExchServDocStatus.DocExchStatusDrillDown(Rec);
                    end;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cr. Memo")
            {
                Caption = '&Cr. Memo';
                Image = CreditMemo;
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Service Credit Memo Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = Type = const(General),
                                  "Table Name" = const("Service Cr.Memo Header"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            action(SendCustom)
            {
                ApplicationArea = Service;
                Caption = 'Send';
                Ellipsis = true;
                Image = SendToMultiple;
                ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                trigger OnAction()
                begin
                    ServCrMemoHeader := Rec;
                    CurrPage.SetSelectionFilter(ServCrMemoHeader);
                    ServCrMemoHeader.SendRecords();
                end;
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(ServCrMemoHeader);
                    ServCrMemoHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Service;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action(ActivityLog)
            {
                ApplicationArea = Service;
                Caption = 'Activity Log';
                Image = Log;
                ToolTip = 'View the status and any errors if the document was sent as an electronic document or OCR file through the document exchange service.';

                trigger OnAction()
                var
                    ActivityLog: Record "Activity Log";
                begin
                    ActivityLog.ShowEntries(Rec.RecordId);
                end;
            }
            action("Update Document")
            {
                ApplicationArea = Service;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedServCrMemoUpdate: Page "Posted Serv. Cr. Memo - Update";
                begin
                    PostedServCrMemoUpdate.LookupMode := true;
                    PostedServCrMemoUpdate.SetRec(Rec);
                    PostedServCrMemoUpdate.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Update Document_Promoted"; "Update Document")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref(SendCustom_Promoted; SendCustom)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                group("Category_Credit Memo")
                {
                    Caption = 'Credit Memo';

                    actionref(Statistics_Promoted; Statistics)
                    {
                    }
                    actionref("Co&mments_Promoted"; "Co&mments")
                    {
                    }
                    actionref(ActivityLog_Promoted; ActivityLog)
                    {
                    }
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
    end;

    trigger OnAfterGetRecord()
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
    end;

    trigger OnOpenPage()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        Rec.SetSecurityFilterOnRespCenter();

        ServiceCrMemoHeader.CopyFilters(Rec);
        ServiceCrMemoHeader.SetFilter("Document Exchange Status", '<>%1', Rec."Document Exchange Status"::"Not Sent");
        DocExchStatusVisible := not ServiceCrMemoHeader.IsEmpty();
    end;

    var
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        DocExchStatusStyle: Text;
        DocExchStatusVisible: Boolean;
}

