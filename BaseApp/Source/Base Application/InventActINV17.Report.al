report 14914 "Invent. Act INV-17"
{
    Caption = 'Invent. Act INV-17';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Invent. Act Header"; "Invent. Act Header")
        {
            PrintOnlyIfDetail = true;
            dataitem(DebtsInventActLine; "Invent. Act Line")
            {
                DataItemLink = "Act No." = FIELD("No.");
                DataItemTableView = SORTING("Act No.", "Contractor Type", "Contractor No.", "G/L Account No.", Category) WHERE(Category = CONST(Debts));

                trigger OnAfterGetRecord()
                begin
                    SummarizeTotal(LastTotal, DebtsInventActLine);
                    FillLine(DebtsInventActLine, false);

                    SummarizeTotal(PageTotal, DebtsInventActLine);
                end;

                trigger OnPostDataItem()
                begin
                    FillLine(DebtsInventActLine, true);
                    INV17Helper.FillPageFooter(LastTotal);
                end;

                trigger OnPreDataItem()
                begin
                    INV17Helper.FillPartHeader(Category::Debts);
                end;
            }
            dataitem(LiabilitiesInventActLine; "Invent. Act Line")
            {
                DataItemLink = "Act No." = FIELD("No.");
                DataItemTableView = SORTING("Act No.", "Contractor Type", "Contractor No.", "G/L Account No.", Category) WHERE(Category = CONST(Liabilities));

                trigger OnAfterGetRecord()
                begin
                    SummarizeTotal(LastTotal, LiabilitiesInventActLine);
                    FillLine(LiabilitiesInventActLine, false);

                    SummarizeTotal(PageTotal, LiabilitiesInventActLine);
                end;

                trigger OnPostDataItem()
                begin
                    FillLine(LiabilitiesInventActLine, true);
                    INV17Helper.FillPageFooter(LastTotal);
                end;

                trigger OnPreDataItem()
                begin
                    Clear(PageTotal);
                    Clear(LastTotal);
                    Clear(LastInvActLine);
                    INV17Helper.FillPartHeader(Category::Liabilities);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                INV17Helper.CheckSignature(Chairman, "No.", Chairman."Employee Type"::Chairman);
                INV17Helper.CheckSignature(Member1, "No.", Member1."Employee Type"::Member1);
                INV17Helper.CheckSignature(Member2, "No.", Member2."Employee Type"::Member2);

                INV17Helper.FillHeader(
                  "No.", Format("Act Date"), "Reason Document No.", Format("Reason Document Date"), "Inventory Date");
            end;

            trigger OnPostDataItem()
            begin
                INV17Helper.FillFooter(
                  StdRepMgt.GetEmpPosition(Chairman."Employee No."),
                  StdRepMgt.GetEmpName(Chairman."Employee No."),
                  StdRepMgt.GetEmpPosition(Member1."Employee No."),
                  StdRepMgt.GetEmpName(Member1."Employee No."),
                  StdRepMgt.GetEmpPosition(Member2."Employee No."),
                  StdRepMgt.GetEmpName(Member2."Employee No."));
            end;

            trigger OnPreDataItem()
            begin
                CompanyInformation.Get;
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

    trigger OnPostReport()
    begin
        if FileName = '' then
            INV17Helper.ExportData
        else
            INV17Helper.ExportDataFile(FileName);
    end;

    trigger OnPreReport()
    begin
        INV17Helper.InitReportTemplate(REPORT::"Invent. Act INV-17");
    end;

    var
        CompanyInformation: Record "Company Information";
        Chairman: Record "Document Signature";
        Member1: Record "Document Signature";
        Member2: Record "Document Signature";
        LastInvActLine: Record "Invent. Act Line";
        DocSignMgt: Codeunit "Doc. Signature Management";
        StdRepMgt: Codeunit "Local Report Management";
        INV17Helper: Codeunit "INV-17 Report Helper";
        PageTotal: array[4] of Decimal;
        LastTotal: array[4] of Decimal;
        FileName: Text;

    local procedure FillLine(InvActLine: Record "Invent. Act Line"; Finalize: Boolean)
    begin
        with InvActLine do
            if LastInvActLine."Act No." <> '' then
                if IsGroupChanged(InvActLine) or Finalize then begin
                    INV17Helper.FillLine(LastInvActLine."Contractor Name", LastInvActLine."G/L Account No.", PageTotal, LastTotal, Category);
                    Clear(PageTotal);
                end;
        LastInvActLine := InvActLine;
    end;

    local procedure IsGroupChanged(InvActLine: Record "Invent. Act Line"): Boolean
    begin
        with InvActLine do
            exit(
              (LastInvActLine."Contractor Type" <> "Contractor Type") or
              (LastInvActLine."Contractor No." <> "Contractor No.") or
              (LastInvActLine."G/L Account No." <> "G/L Account No.") or
              (LastInvActLine.Category <> Category));
    end;

    local procedure SummarizeTotal(var TotalAmount: array[4] of Decimal; InvActLine: Record "Invent. Act Line")
    begin
        with InvActLine do begin
            TotalAmount[1] += "Total Amount";
            TotalAmount[2] += "Confirmed Amount";
            TotalAmount[3] += "Not Confirmed Amount";
            TotalAmount[4] += "Overdue Amount";
        end;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

