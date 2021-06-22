page 5784 "Filters to Get Source Docs."
{
    Caption = 'Filters to Get Source Docs.';
    PageType = Worksheet;
    RefreshOnActivate = true;
    SourceTable = "Warehouse Source Filter";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ShowRequestForm; ShowRequestForm)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Filter Request';
                    ToolTip = 'Specifies if the Filters to Get Source Docs. window appears when you choose Use Filters to Get Source Docs on a warehouse shipment or warehouse receipt document.';
                }
                field("Do Not Fill Qty. to Handle"; "Do Not Fill Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that inventory quantities are assigned when you get outbound source document lines for shipment.';
                }
            }
            repeater(Control1)
            {
                Editable = true;
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code that identifies the filter record.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of filter combinations in the Source Document Filter Card window to retrieve lines from source documents.';
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
        area(processing)
        {
            action(Run)
            {
                ApplicationArea = Warehouse;
                Caption = '&Run';
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Get the specified source documents.';

                trigger OnAction()
                var
                    GetSourceBatch: Report "Get Source Documents";
                begin
                    case RequestType of
                        RequestType::Receive:
                            begin
                                GetSourceBatch.SetOneCreatedReceiptHeader(WhseReceiptHeader);
                                SetFilters(GetSourceBatch, WhseReceiptHeader."Location Code");
                            end;
                        RequestType::Ship:
                            begin
                                GetSourceBatch.SetOneCreatedShptHeader(WhseShptHeader);
                                SetFilters(GetSourceBatch, WhseShptHeader."Location Code");
                                GetSourceBatch.SetSkipBlocked(true);
                            end;
                    end;

                    GetSourceBatch.SetSkipBlockedItem(true);
                    GetSourceBatch.UseRequestPage(ShowRequestForm);
                    GetSourceBatch.RunModal;
                    if GetSourceBatch.NotCancelled then
                        CurrPage.Close;
                end;
            }
            action(Modify)
            {
                ApplicationArea = Warehouse;
                Caption = '&Modify';
                Image = EditFilter;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Change the type of source documents that the function looks in.';

                trigger OnAction()
                var
                    SourceDocFilterCard: Page "Source Document Filter Card";
                begin
                    TestField(Code);
                    case RequestType of
                        RequestType::Receive:
                            SourceDocFilterCard.SetOneCreatedReceiptHeader(WhseReceiptHeader);
                        RequestType::Ship:
                            SourceDocFilterCard.SetOneCreatedShptHeader(WhseShptHeader);
                    end;
                    SourceDocFilterCard.SetRecord(Rec);
                    SourceDocFilterCard.SetTableView(Rec);
                    SourceDocFilterCard.RunModal;
                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ShowRequestForm := "Show Filter Request";
    end;

    trigger OnOpenPage()
    begin
        DataCaption := CurrPage.Caption;
        FilterGroup := 2;
        if GetFilter(Type) <> '' then
            DataCaption := DataCaption + ' - ' + GetFilter(Type);
        FilterGroup := 0;
        CurrPage.Caption(DataCaption);
    end;

    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        DataCaption: Text[250];
        ShowRequestForm: Boolean;
        RequestType: Option Receive,Ship;

    procedure SetOneCreatedShptHeader(WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        RequestType := RequestType::Ship;
        WhseShptHeader := WhseShptHeader2;
    end;

    procedure SetOneCreatedReceiptHeader(WhseReceiptHeader2: Record "Warehouse Receipt Header")
    begin
        RequestType := RequestType::Receive;
        WhseReceiptHeader := WhseReceiptHeader2;
    end;
}

