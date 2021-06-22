report 99003803 "Copy Production Forecast"
{
    Caption = 'Copy Demand Forecast';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Production Forecast Entry"; "Production Forecast Entry")
        {
            DataItemTableView = SORTING("Entry No.");
            RequestFilterFields = "Production Forecast Name", "Item No.";

            trigger OnAfterGetRecord()
            begin
                if "Entry No." > LastEntryNo then
                    CurrReport.Break();
                ProdForecastEntry2 := "Production Forecast Entry";

                if ToProdForecastEntry."Production Forecast Name" <> '' then
                    ProdForecastEntry2."Production Forecast Name" := ToProdForecastEntry."Production Forecast Name";
                if ToProdForecastEntry."Item No." <> '' then
                    ProdForecastEntry2."Item No." := ToProdForecastEntry."Item No.";
                if ToProdForecastEntry."Location Code" <> '' then
                    ProdForecastEntry2."Location Code" := ToProdForecastEntry."Location Code";
                ProdForecastEntry2."Component Forecast" := ToProdForecastEntry."Component Forecast";
                if Format(ChangeDateExpression) <> '' then
                    ProdForecastEntry2."Forecast Date" := CalcDate(ChangeDateExpression, "Forecast Date");

                ProdForecastEntry2."Entry No." := NextEntryNo;
                OnBeforeProdForecastEntryInsert(ProdForecastEntry2, ToProdForecastEntry);
                ProdForecastEntry2.Insert();
                NextEntryNo := NextEntryNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                if not Confirm(Text000, false) then
                    exit;

                LockTable();

                LastEntryNo := ProdForecastEntry2.GetLastEntryNo();
                NextEntryNo := LastEntryNo + 1;

                ProdForecastName.SetRange(Name, ToProdForecastEntry."Production Forecast Name");
                if not ProdForecastName.FindFirst then begin
                    ProdForecastName.Name := ToProdForecastEntry."Production Forecast Name";
                    ProdForecastName.Insert();
                end;
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
                group(Options)
                {
                    Caption = 'Options';
                    group("Copy to")
                    {
                        Caption = 'Copy to';
                        field(ProductionForecastName; ToProdForecastEntry."Production Forecast Name")
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Demand Forecast Name';
                            TableRelation = "Production Forecast Name";
                            ToolTip = 'Specifies the name of the demand forecast to which you want to copy the entries. Before you can select a demand forecast name, it must be set up in the Demand Forecast Names window, which you open by clicking the field.';
                        }
                        field(ItemNo; ToProdForecastEntry."Item No.")
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Item No.';
                            TableRelation = Item;
                            ToolTip = 'Specifies the number of the item to which you want to copy the entries. To see the existing item numbers, click the field.';
                        }
                        field(LocationCode; ToProdForecastEntry."Location Code")
                        {
                            ApplicationArea = Location;
                            Caption = 'Location Code';
                            TableRelation = Location;
                            ToolTip = 'Specifies a location for the demand forecast to which you are copying entries.';
                        }
                    }
                    field(ComponentForecast; ToProdForecastEntry."Component Forecast")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Component Forecast';
                        ToolTip = 'Specifies whether the entry is for a component item. Leave the field blank if the entry is for a sales item.';
                    }
                    field(DateChangeFormula; ChangeDateExpression)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Date Change Formula';
                        ToolTip = 'Specifies how the dates on the entries that are copied will be changed. Use a date formula; for example, to copy last week''s forecast to this week, use the formula 1W (one week).';
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

    var
        Text000: Label 'Do you want to copy the demand forecast?';
        ToProdForecastEntry: Record "Production Forecast Entry";
        ProdForecastEntry2: Record "Production Forecast Entry";
        ProdForecastName: Record "Production Forecast Name";
        ChangeDateExpression: DateFormula;
        LastEntryNo: Integer;
        NextEntryNo: Integer;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdForecastEntryInsert(var ProdForecastEntry: Record "Production Forecast Entry"; ToProdForecastEntry: Record "Production Forecast Entry")
    begin
    end;
}

