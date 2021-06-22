/// <summary>
/// Copies pricing data from old tables to "Price List Line" and "Price List Header" table.
/// </summary>
Codeunit 7049 "Feature - Price Calculation" implements "Feature Data Update"
{
    procedure IsDataUpdateRequired(): Boolean;
    begin
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty);
    end;

    procedure ReviewData();
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
        Codeunit.Run(Codeunit::"Price Calculation Mgt.");
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        JobItemPrice: Record "Job Item Price";
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobResourcePrice: Record "Job Resource Price";
        ResourceCost: Record "Resource Cost";
        ResourcePrice: Record "Resource Price";
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.SetGenerateHeader();

        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, SalesPrice.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, SalesLineDiscount.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, PurchasePrice.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, PurchaseLineDiscount.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, JobItemPrice.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, JobGLAccountPrice.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, JobResourcePrice.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(ResourceCost, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ResourceCost.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(ResourcePrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ResourcePrice.TableCaption(), StartDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := StrSubstNo(DescrTok, GetListOfTables(), Description2Txt);
    end;

    var
        PriceListLine: Record "Price List Line";
        TempDocumentEntry: Record "Document Entry" temporary;
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        Description1Txt: Label 'Records from %1, %2, %3, %4, %5, %6, %7, %8, %9, and %10 tables',
            Comment = '%1, %2, %3, %4, %5, %6, %7, %8, %9, %10 - table captions';
        Description2Txt: Label 'will be copied to the Price List Header and Price List Line tables.';
        DescrTok: Label '%1 %2', Locked = true;

    local procedure CountRecords()
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        JobItemPrice: Record "Job Item Price";
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobResourcePrice: Record "Job Resource Price";
        ResourceCost: Record "Resource Cost";
        ResourcePrice: Record "Resource Price";
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        InsertDocumentEntry(Database::"Sales Price", SalesPrice.TableCaption, SalesPrice.Count());
        InsertDocumentEntry(Database::"Sales Line Discount", SalesLineDiscount.TableCaption, SalesLineDiscount.Count());
        InsertDocumentEntry(Database::"Purchase Price", PurchasePrice.TableCaption, PurchasePrice.Count());
        InsertDocumentEntry(Database::"Purchase Line Discount", PurchaseLineDiscount.TableCaption, PurchaseLineDiscount.Count());
        InsertDocumentEntry(Database::"Job Item Price", JobItemPrice.TableCaption, JobItemPrice.Count());
        InsertDocumentEntry(Database::"Job G/L Account Price", JobGLAccountPrice.TableCaption, JobGLAccountPrice.Count());
        InsertDocumentEntry(Database::"Job Resource Price", JobResourcePrice.TableCaption, JobResourcePrice.Count());
        InsertDocumentEntry(Database::"Resource Price", ResourcePrice.TableCaption, ResourcePrice.Count());
        InsertDocumentEntry(Database::"Resource Cost", ResourceCost.TableCaption, ResourceCost.Count());
    end;

    local procedure GetListOfTables(): Text;
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        JobItemPrice: Record "Job Item Price";
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobResourcePrice: Record "Job Resource Price";
        ResourceCost: Record "Resource Cost";
        ResourcePrice: Record "Resource Price";
    begin
        exit(
            StrSubstNo(
                Description1Txt,
                SalesPrice.TableCaption(), SalesLineDiscount.TableCaption(),
                PurchasePrice.TableCaption(), PurchaseLineDiscount.TableCaption(),
                JobItemPrice.TableCaption(), JobGLAccountPrice.TableCaption(), JobResourcePrice.TableCaption(),
                JobResourcePrice.TableCaption(), ResourcePrice.TableCaption(), ResourceCost.TableCaption()));
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." += 1;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;
}