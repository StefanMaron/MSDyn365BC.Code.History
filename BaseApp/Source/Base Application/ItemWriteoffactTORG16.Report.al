report 14930 "Item Write-off act TORG-16"
{
    Caption = 'Item Write-off act TORG-16';
    ProcessingOnly = true;

    dataset
    {
        dataitem(ItemDocHeader; "Item Document Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Shipment));
            RequestFilterFields = "Document Type", "No.";
            dataitem(ItemDocLine1; "Item Document Line")
            {
                DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    Torg16DocHelper.FillWriteOffReasonBody("Applies-to Entry", "Reason Code", ItemDocHeader."Posting Date");
                end;

                trigger OnPostDataItem()
                begin
                    Torg16DocHelper.FillPageFooter;
                    Torg16DocHelper.InitSecondSheet;
                end;

                trigger OnPreDataItem()
                begin
                    Torg16DocHelper.FillPageHeader;
                end;
            }
            dataitem(ItemDocLine2; "Item Document Line")
            {
                DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    Torg16DocHelper.FillItemLedgerLine("Item No.", "Unit of Measure Code", ItemDocLine2);
                end;

                trigger OnPostDataItem()
                begin
                    Torg16DocHelper.FillFooter(WriteOffSource, Member);
                end;

                trigger OnPreDataItem()
                begin
                    Torg16DocHelper.FillPageHeader2;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FillHeader(ItemDocHeader);
                FillHeaderSignatures("No.");
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(OperationType; OperationType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation Type';
                        ToolTip = 'Specifies the type of the related operation, for the purpose of VAT reporting.';
                    }
                    field(OrderNo; OrderNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Order No.';
                        ToolTip = 'Specifies the number of the related order.';
                    }
                    field(OrderDate; OrderDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Order Date';
                        ToolTip = 'Specifies the creation date of the related order.';
                    }
                    field(WriteOffSource; WriteOffSource)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Write-off Source';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName <> '' then
            Torg16DocHelper.ExportDataFile(FileName)
        else
            Torg16DocHelper.ExportData
    end;

    trigger OnPreReport()
    begin
        Torg16DocHelper.InitReportTemplate;
    end;

    var
        DocSignature: Record "Document Signature";
        Torg16DocHelper: Codeunit "Torg-16 Document Helper";
        Member: array[5, 2] of Text[100];
        OperationType: Text;
        OrderNo: Text;
        OrderDate: Date;
        WriteOffSource: Text;
        FileName: Text;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewOperationType: Text; NewOrderNo: Text; NewOrderDate: Date; NewWriteOffSource: Text)
    begin
        OperationType := NewOperationType;
        OrderNo := NewOrderNo;
        OrderDate := NewOrderDate;
        WriteOffSource := NewWriteOffSource;
    end;

    local procedure FillHeader(ItemDocHeader: Record "Item Document Header")
    begin
        Torg16DocHelper.FillHeader(
          ItemDocHeader."No.", ItemDocHeader."Document Date", ItemDocHeader."Location Code",
          OrderNo, OrderDate, OperationType);
    end;

    local procedure FillHeaderSignatures(ItemDocNo: Code[20])
    begin
        ProcessSignatures(ItemDocNo);
        Torg16DocHelper.FillHeaderSignatures(Member);
    end;

    local procedure ProcessSignatures(ItemDocNo: Code[20])
    var
        Employee: Record Employee;
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        if DocSignature.Get(12450, 1, ItemDocNo, DocSignature."Employee Type"::Chairman) then begin
            Member[1, 1] := DocSignature."Employee Job Title";
            Member[1, 2] := DocSignature."Employee Name";
        end;
        if DocSignature.Get(12450, 1, ItemDocNo, DocSignature."Employee Type"::Member1) then begin
            Member[2, 1] := DocSignature."Employee Job Title";
            Member[2, 2] := DocSignature."Employee Name";
        end;
        if DocSignature.Get(12450, 1, ItemDocNo, DocSignature."Employee Type"::Member2) then begin
            Member[3, 1] := DocSignature."Employee Job Title";
            Member[3, 2] := DocSignature."Employee Name";
        end;
        if DocSignature.Get(12450, 1, ItemDocNo, DocSignature."Employee Type"::StoredBy) then begin
            Member[4, 1] := DocSignature."Employee Job Title";
            Member[4, 2] := DocSignature."Employee Name";
        end;
        if Employee.Get(CompanyInfo."Director No.") then begin
            Member[5, 1] := Employee.GetJobTitleName;
            Member[5, 2] := CompanyInfo."Director Name";
        end;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

