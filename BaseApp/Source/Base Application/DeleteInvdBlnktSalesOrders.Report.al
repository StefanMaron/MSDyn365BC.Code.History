report 291 "Delete Invd Blnkt Sales Orders"
{
    AccessByPermission = TableData "Sales Header" = RD;
    ApplicationArea = Suite;
    Caption = 'Delete Invoiced Blanket Sales Orders';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST("Blanket Order"));
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Blanket Sales Order';

            trigger OnAfterGetRecord()
            var
                ATOLink: Record "Assemble-to-Order Link";
                ApprovalsMgmt: Codeunit "Approvals Mgmt.";
            begin
                OnSalesHeaderOnBeforeOnAfterGetRecord("Sales Header");

                Window.Update(1, "No.");

                SalesLine.Reset();
                SalesLine.SetRange("Document Type", "Document Type");
                SalesLine.SetRange("Document No.", "No.");
                SalesLine.SetFilter("Quantity Invoiced", '<>0');
                if SalesLine.FindFirst then begin
                    SalesLine.SetRange("Quantity Invoiced");
                    SalesLine.SetFilter("Outstanding Quantity", '<>0');
                    OnAfterSetSalesLineFilters(SalesLine);
                    if not SalesLine.FindFirst then begin
                        SalesLine.SetRange("Outstanding Quantity");
                        SalesLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                        if not SalesLine.FindFirst then begin
                            SalesLine.LockTable();
                            if not SalesLine.FindFirst then begin
                                SalesLine.SetRange("Qty. Shipped Not Invoiced");
                                SalesLine2.SetRange("Blanket Order No.", "No.");
                                if not SalesLine2.FindFirst then begin
                                    ArchiveManagement.AutoArchiveSalesDocument("Sales Header");
                                    SalesLine.SetFilter("Qty. to Assemble to Order", '<>0');
                                    if SalesLine.FindSet then
                                        repeat
                                            ATOLink.DeleteAsmFromSalesLine(SalesLine);
                                        until SalesLine.Next = 0;
                                    SalesLine.SetRange("Qty. to Assemble to Order");
                                    OnBeforeDeleteSalesLines(SalesLine);
                                    SalesLine.DeleteAll();

                                    SalesCommentLine.SetRange("Document Type", "Document Type");
                                    SalesCommentLine.SetRange("No.", "No.");
                                    SalesCommentLine.DeleteAll();

                                    ApprovalsMgmt.DeleteApprovalEntries(RecordId);

                                    OnBeforeDeleteSalesHeader("Sales Header");
                                    Delete;

                                    Commit();
                                end;
                            end;
                        end;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text000: Label 'Processing sales orders #1##########';
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
        ArchiveManagement: Codeunit ArchiveManagement;
        Window: Dialog;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesLines(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesHeaderOnBeforeOnAfterGetRecord(var SalesHeader: Record "Sales Header")
    begin
    end;
}

