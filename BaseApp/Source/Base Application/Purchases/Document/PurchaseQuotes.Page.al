﻿namespace Microsoft.Purchases.Document;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Automation;

page 9306 "Purchase Quotes"
{
    AdditionalSearchTerms = 'rfq,request for quote,purchase requisition';
    ApplicationArea = Suite;
    Caption = 'Purchase Quotes';
    CardPageID = "Purchase Quote";
    DataCaptionFields = "Buy-from Vendor No.";
    Editable = false;
    PageType = List;
    QueryCategory = 'Purchase Quotes';
    RefreshOnActivate = true;
    SourceTable = "Purchase Header";
    SourceTableView = where("Document Type" = const(Quote));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the order address of the related vendor.';
                    Visible = false;
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Vendor Authorization No."; Rec."Vendor Authorization No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the compensation agreement identification number, sometimes referred to as the RMA No. (Returns Materials Authorization).';
                }
                field("Buy-from Post Code"; Rec."Buy-from Post Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the post code of the vendor who delivered the items.';
                    Visible = false;
                }
                field("Buy-from Country/Region Code"; Rec."Buy-from Country/Region Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the city of the vendor who delivered the items.';
                    Visible = false;
                }
                field("Buy-from Contact"; Rec."Buy-from Contact")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the contact person at the vendor who delivered the items.';
                    Visible = false;
                }
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
                    Visible = false;
                }
                field("Pay-to Name"; Rec."Pay-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor who you received the invoice from.';
                    Visible = false;
                }
                field("Pay-to Post Code"; Rec."Pay-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the post code of the vendor that you received the invoice from.';
                    Visible = false;
                }
                field("Pay-to Country/Region Code"; Rec."Pay-to Country/Region Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the country/region code of the address.';
                    Visible = false;
                }
                field("Pay-to Contact"; Rec."Pay-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person to contact about an invoice from this vendor.';
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the posting of the purchase document will be recorded.';
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
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                    Visible = false;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the currency of the amounts on the purchase lines.';
                    Visible = false;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the campaign that the document is linked to.';
                    Visible = false;
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s reference.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the record is open, waiting to be approved, invoiced for prepayment, or released to the next stage of processing.';
                    Visible = false;
                    StyleExpr = StatusStyleTxt;
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"Purchase Header"),
                              "No." = field("No."),
                              "Document Type" = field("Document Type");
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Suite;
                ShowFilter = false;
                Visible = false;
            }
            part(Control1901138007; "Vendor Details FactBox")
            {
                ApplicationArea = Suite;
                SubPageLink = "No." = field("Buy-from Vendor No."),
                              "Date Filter" = field("Date Filter");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Quote")
            {
                Caption = '&Quote';
                Image = Quote;
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        Rec.OpenDocumentStatistics();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "No." = field("No."),
                                  "Document Line No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                    end;
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OpenApprovalsPurchase(Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            action(MakeOrder)
            {
                ApplicationArea = Suite;
                Caption = 'Make &Order';
                Image = MakeOrder;
                ToolTip = 'Convert the purchase quote to a purchase order.';

                trigger OnAction()
                var
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    if ApprovalsMgmt.PrePostApprovalCheckPurch(Rec) then
                        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order (Yes/No)", Rec);
                end;
            }
            group(Action12)
            {
                Caption = 'Print';
                Image = Print;
                action(Print)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Print';
                    Ellipsis = true;
                    Image = Print;
                    ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
                    begin
                        LinesInstructionMgt.PurchaseCheckAllLinesHaveQuantityAssigned(Rec);

                        DocPrint.PrintPurchHeader(Rec);
                    end;
                }
                action(Send)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send';
                    Ellipsis = true;
                    Image = SendToMultiple;
                    ToolTip = 'Prepare to send the document according to the vendor''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                    trigger OnAction()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        PurchaseHeader := Rec;
                        CurrPage.SetSelectionFilter(PurchaseHeader);
                        PurchaseHeader.SendRecords();
                    end;
                }
                action(AttachAsPDF)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attach as PDF';
                    Image = PrintAttachment;
                    ToolTip = 'Create a PDF file and attach it to the document.';

                    trigger OnAction()
                    var
                        PurchaseHeader: Record "Purchase Header";
                        DocPrint: Codeunit "Document-Print";
                    begin
                        PurchaseHeader := Rec;
                        CurrPage.SetSelectionFilter(PurchaseHeader);
                        DocPrint.PrintPurchaseHeaderToDocumentAttachment(PurchaseHeader);
                    end;
                }
            }
            group(Action3)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        CurrPage.SetSelectionFilter(PurchaseHeader);
                        Rec.PerformManualRelease(PurchaseHeader);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed';

                    trigger OnAction()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        CurrPage.SetSelectionFilter(PurchaseHeader);
                        Rec.PerformManualReopen(PurchaseHeader);
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = "Action";
                action(SendApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = not OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval of the document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckPurchaseApprovalPossible(Rec) then
                            ApprovalsMgmt.OnSendPurchaseDocForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelPurchaseApprovalRequest(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(MakeOrder_Promoted; MakeOrder)
                {
                }
            }
            group(Category_Release)
            {
                Caption = 'Release';
                ShowAs = SplitButton;

                actionref(Release_Promoted; Release)
                {
                }
                actionref(Reopen_Promoted; Reopen)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Print_Promoted; Print)
                {
                }
                actionref(Send_Promoted; Send)
                {
                }
                actionref(AttachAsPDF_Promoted; AttachAsPDF)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 3.';

#if not CLEAN22
                actionref(SendApprovalRequest_Promoted; SendApprovalRequest)
                {
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Action is being demoted based on overall low usage.';
                    ObsoleteTag = '22.0';
                }
#endif
#if not CLEAN22
                actionref(CancelApprovalRequest_Promoted; CancelApprovalRequest)
                {
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Action is being demoted based on overall low usage.';
                    ObsoleteTag = '22.0';
                }
#endif
            }
            group(Category_Category6)
            {
                Caption = 'Quote', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StatusStyleTxt := Rec.GetStatusStyleText();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetControlAppearance();
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
    end;

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();

        Rec.CopyBuyFromVendorFilter();
    end;

    var
        DocPrint: Codeunit "Document-Print";
        OpenApprovalEntriesExist: Boolean;
        CanCancelApprovalForRecord: Boolean;
        StatusStyleTxt: Text;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);

        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId);
    end;
}

