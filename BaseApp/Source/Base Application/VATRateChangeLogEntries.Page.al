page 553 "VAT Rate Change Log Entries"
{
    Caption = 'VAT Rate Change Log Entries';
    Editable = false;
    PageType = List;
    SourceTable = "VAT Rate Change Log Entry";
    SourceTableView = SORTING("Entry No.");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Record Identifier"; Format("Record ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record Identifier';
                    ToolTip = 'Specifies the location of this line in the printed or exported VAT report.';
                }
                field("Old Gen. Prod. Posting Group"; "Old Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general product posting group before the VAT rate change conversion.';
                }
                field("New Gen. Prod. Posting Group"; "New Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the new general product posting group after the VAT rate change conversion.';
                }
                field("Old VAT Prod. Posting Group"; "Old VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group before the VAT rate change conversion.';
                }
                field("New VAT Prod. Posting Group"; "New VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new VAT product posting group after the VAT rate change conversion.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for the VAT rate change conversion.';
                }
                field(Converted; Converted)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the VAT rate change conversion.';
                }
                field("Converted Date"; "Converted Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the VAT rate change log entry was created.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Show)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Show';
                    Ellipsis = true;
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'View the log details.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        SalesLine: Record "Sales Line";
                        PurchaseHeader: Record "Purchase Header";
                        PurchaseLine: Record "Purchase Line";
                        ServiceHeader: Record "Service Header";
                        ServiceLine: Record "Service Line";
                        PageManagement: Codeunit "Page Management";
                        RecRef: RecordRef;
                        IsHandled: Boolean;
                    begin
                        if Format("Record ID") = '' then
                            exit;
                        if not RecRef.Get("Record ID") then
                            Error(Text0002);

                        case "Table ID" of
                            DATABASE::"Sales Header",
                          DATABASE::"Purchase Header",
                          DATABASE::"Gen. Journal Line",
                          DATABASE::Item,
                          DATABASE::"G/L Account",
                          DATABASE::"Item Category",
                          DATABASE::"Item Charge",
                          DATABASE::Resource:
                                PageManagement.PageRunModal(RecRef);
                            DATABASE::"Sales Line":
                                begin
                                    RecRef.SetTable(SalesLine);
                                    SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                                    PageManagement.PageRunModal(SalesHeader);
                                end;
                            DATABASE::"Purchase Line":
                                begin
                                    RecRef.SetTable(PurchaseLine);
                                    PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
                                    PageManagement.PageRunModal(PurchaseHeader);
                                end;
                            DATABASE::"Service Line":
                                begin
                                    RecRef.SetTable(ServiceLine);
                                    ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
                                    PageManagement.PageRunModal(ServiceHeader);
                                end;
                            else begin
                                    IsHandled := false;
                                    OnAfterShow(Rec, IsHandled);
                                    if not IsHandled then
                                        Message(Text0001);
                                end;
                        end;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields("Table Caption")
    end;

    var
        Text0001: Label 'Search for the pages to see this entry.';
        Text0002: Label 'The related entry has been posted or deleted.';

    [IntegrationEvent(false, false)]
    local procedure OnAfterShow(VATRateChangeLogEntry: Record "VAT Rate Change Log Entry"; var IsHandled: Boolean)
    begin
    end;
}

