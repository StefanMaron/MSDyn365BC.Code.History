report 31078 "Posted Inventory Document"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PostedInventoryDocument.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Inventory Document';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Item Register"; "Item Register")
        {
            DataItemTableView = SORTING("No.");

            trigger OnAfterGetRecord()
            begin
                ItemReg := "Item Register";
                CurrReport.Break;
            end;

            trigger OnPreDataItem()
            begin
                if "Item Register".GetFilters = '' then
                    CurrReport.Break;
            end;
        }
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableView = SORTING("Document No.", "Document Type", "Document Line No.") WHERE(Quantity = FILTER(<> 0));
            RequestFilterFields = "Document No.", "Posting Date";
            column(ReportCaption; Text001)
            {
            }
            column(CompanyName; StrSubstNo('%1 %2', CompanyInfo.Name, CompanyInfo."Name 2"))
            {
            }
            column(CompanyAddress; StrSubstNo('%1 %2', CompanyInfo.Address, CompanyInfo."Address 2"))
            {
            }
            column(CompanyCity; StrSubstNo('%1 %2', CompanyInfo."Post Code", CompanyInfo.City))
            {
            }
            column(CompanyRegNo; StrSubstNo('%1: %2', CompanyInfo.FieldCaption("Registration No."), CompanyInfo."Registration No."))
            {
            }
            column(CompanyVATRegNo; StrSubstNo('%1: %2', CompanyInfo.FieldCaption("VAT Registration No."), CompanyInfo."VAT Registration No."))
            {
            }
            column(EntryType; EntryType)
            {
            }
            column(DocumentNo; "Document No.")
            {
            }
            column(PageNo; CurrReport.PageNo)
            {
            }
            column(IssueDate; Format("Document Date", 0, 4))
            {
            }
            column(RegUserID; "Item Register"."User ID")
            {
            }
            column(PostingDate; Format("Posting Date", 0, 4))
            {
            }
            column(PageCaption; PageCaption)
            {
            }
            column(IssueDateCaption; IssueDateCaption)
            {
            }
            column(PostedByCaption; PostedByCaption)
            {
            }
            column(PostingDateCaption; StrSubstNo('%1: ', FieldCaption("Posting Date")))
            {
            }
            column(ILE_EntryType; "Entry Type")
            {
                IncludeCaption = true;
            }
            column(ILE_PostingDate; "Posting Date")
            {
                IncludeCaption = true;
            }
            column(ILE_ItemNo; "Item No.")
            {
                IncludeCaption = true;
            }
            column(DescriptionText; DescriptionText)
            {
            }
            column(ILE_LocationCode; "Location Code")
            {
                IncludeCaption = true;
            }
            column(ILE_UoM; UnitOfMeasureCode)
            {
            }
            column(ILE_UoMCaption; FieldCaption("Unit of Measure Code"))
            {
            }
            column(ILE_UnitPrice; UnitPrice)
            {
            }
            column(ILE_Qty; Quantity)
            {
                IncludeCaption = true;
            }
            column(ILE_Amount; "Cost Amount (Actual)")
            {
            }
            column(ILE_Description; Description)
            {
                IncludeCaption = true;
            }
            column(ILE_UnitPriceCaption; UnitPriceCaption)
            {
            }
            column(ILE_AmountCaption; AmountCaption)
            {
            }
            column(ILE_QuantityUoM; QuantityUoM)
            {
            }
            column(TotalCaption; TotalCaption)
            {
            }

            trigger OnAfterGetRecord()
            var
                ILE: Record "Item Ledger Entry";
            begin
                if Description <> '' then begin
                    DescriptionText := Description;
                end else begin
                    Item.Get("Item No.");
                    DescriptionText :=
                      CopyStr(Item.Description + ' ' + Item."Description 2", 1, MaxStrLen(DescriptionText));
                end;

                if "Item Register"."User ID" = '' then
                    "Item Register"."User ID" := "User ID";

                if PrintQtyInUoM = PrintQtyInUoM::"Base UoM" then begin
                    if Item."No." <> "Item No." then
                        Item.Get("Item No.");
                    UnitOfMeasureCode := Item."Base Unit of Measure";
                end else
                    UnitOfMeasureCode := "Unit of Measure Code";

                if (PrintQtyInUoM = PrintQtyInUoM::"Movement UoM") and (not ("Qty. per Unit of Measure" in [0, 1])) then
                    QuantityUoM := Round(Quantity / "Qty. per Unit of Measure", 0.00001)
                else
                    QuantityUoM := Quantity;

                CalcFields("Cost Amount (Actual)");

                if QuantityUoM <> 0 then
                    UnitPrice := "Cost Amount (Actual)" / QuantityUoM
                else
                    UnitPrice := 0;

                EntryType := UpperCase(Format("Entry Type"));
                if (CurrentDocNo = '') or (CurrentDocNo <> "Document No.") then begin
                    ILE := ItemLedgerEntry;
                    ILE.SetRange("Document No.", "Document No.");
                    ILE.SetFilter("Entry Type", '<>%1', "Entry Type");
                    if not ILE.IsEmpty then
                        Clear(EntryType);
                    CurrentDocNo := "Document No.";
                end;
            end;

            trigger OnPreDataItem()
            begin
                if ItemReg."No." <> 0 then
                    SetRange("Entry No.", ItemReg."From Entry No.", ItemReg."To Entry No.");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                field(PrintQtyInUoM; PrintQtyInUoM)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Quantity in:';
                    OptionCaption = 'Base Unit of Measure,Movement Unit of Measure';
                    ToolTip = 'Specifies if the base unit of measure or movement unit of measure has to be printed.';
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

    trigger OnPreReport()
    begin
        CompanyInfo.Get;
    end;

    var
        CompanyInfo: Record "Company Information";
        Item: Record Item;
        DescriptionText: Text[100];
        Text001: Label 'Item Movement Document';
        PageCaption: Label 'Page:';
        IssueDateCaption: Label 'Issue date:';
        PostedByCaption: Label 'Posted by:';
        AmountCaption: Label 'Estimated Amount';
        UnitPriceCaption: Label 'Estimated Unit Price';
        TotalCaption: Label 'Total (Quantity, Amount):';
        ItemReg: Record "Item Register";
        UnitPrice: Decimal;
        QuantityUoM: Decimal;
        CurrentDocNo: Code[20];
        EntryType: Text[30];
        PrintQtyInUoM: Option "Base UoM","Movement UoM";
        UnitOfMeasureCode: Code[10];
}

