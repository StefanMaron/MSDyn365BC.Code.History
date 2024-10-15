page 5968 "Service Document Registers"
{
    Caption = 'Service Document Registers';
    DataCaptionFields = "Source Document Type", "Source Document No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Document Register";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Source Document No."; Rec."Source Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service order or service contract.';
                }
                field("Destination Document Type"; Rec."Destination Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of document created from the service order or contract specified in the Source Document No.';
                }
                field("Destination Document No."; Rec."Destination Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the invoice or credit memo, based on the contents of the Destination Document Type field.';
                }
                field(CustNo; CustNo)
                {
                    ApplicationArea = Service;
                    Caption = 'Bill-to Customer No.';
                    Editable = false;
                    TableRelation = Customer;
                    ToolTip = 'Specifies the number of the customer relating to the service document.';
                }
                field(CustName; CustName)
                {
                    ApplicationArea = Service;
                    Caption = 'Bill-to Customer Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer relating to the service document.';
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
            group("&Document")
            {
                Caption = '&Document';
                Image = Document;
                action(Card)
                {
                    ApplicationArea = Service;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        case "Destination Document Type" of
                            "Destination Document Type"::Invoice:
                                begin
                                    ServHeader.Get(ServHeader."Document Type"::Invoice, "Destination Document No.");
                                    PAGE.Run(PAGE::"Service Invoice", ServHeader);
                                end;
                            "Destination Document Type"::"Credit Memo":
                                begin
                                    ServHeader.Get(ServHeader."Document Type"::"Credit Memo", "Destination Document No.");
                                    PAGE.Run(PAGE::"Service Credit Memo", ServHeader);
                                end;
                            "Destination Document Type"::"Posted Invoice":
                                begin
                                    ServInvHeader.Get("Destination Document No.");
                                    PAGE.Run(PAGE::"Posted Service Invoice", ServInvHeader);
                                end;
                            "Destination Document Type"::"Posted Credit Memo":
                                begin
                                    ServCrMemoHeader.Get("Destination Document No.");
                                    PAGE.Run(PAGE::"Posted Service Credit Memo", ServCrMemoHeader);
                                end;
                        end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Card_Promoted; Card)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case "Destination Document Type" of
            "Destination Document Type"::Invoice:
                if ServHeader.Get(ServHeader."Document Type"::Invoice, "Destination Document No.") then begin
                    CustNo := ServHeader."Bill-to Customer No.";
                    CustName := ServHeader."Bill-to Name";
                end;
            "Destination Document Type"::"Credit Memo":
                if ServHeader.Get(ServHeader."Document Type"::"Credit Memo", "Destination Document No.") then begin
                    CustNo := ServHeader."Bill-to Customer No.";
                    CustName := ServHeader."Bill-to Name";
                end;
            "Destination Document Type"::"Posted Invoice":
                if ServInvHeader.Get("Destination Document No.") then begin
                    CustNo := ServInvHeader."Bill-to Customer No.";
                    CustName := ServInvHeader."Bill-to Name";
                end;
            "Destination Document Type"::"Posted Credit Memo":
                if ServCrMemoHeader.Get("Destination Document No.") then begin
                    CustNo := ServCrMemoHeader."Bill-to Customer No.";
                    CustName := ServCrMemoHeader."Bill-to Name";
                end;
        end;
    end;

    var
        ServHeader: Record "Service Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        CustNo: Code[20];
        CustName: Text[100];
}

