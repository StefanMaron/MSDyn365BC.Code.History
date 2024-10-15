codeunit 5523 "API Fix Document Shortcut Dim."
{
    trigger OnRun()
    begin
        UpgradeSalesInvoiceShortcutDimension();
        UpgradePurchInvoiceShortcutDimension();
        UpgradePurchaseOrderShortcutDimension();
        UpgradeSalesOrderShortcutDimension();
        UpgradeSalesQuoteShortcutDimension();
        UpgradeSalesCrMemoShortcutDimension();
    end;

    var
        UpgradeSkippedDueToManyRecordsLbl: Label 'Upgrade procedure %1 skipped due to %2 number of %3 records.', Comment = '%1 = Procedure name, %2 = Number of records, %3 = Table name', Locked = true;

    procedure UpgradeSalesInvoiceShortcutDimension()
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesInvoiceShortcutDimensionsUpgradeTag()) then
            exit;

        SalesInvoiceEntityAggregate.SetLoadFields(Id, "No.", Posted, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if SalesInvoiceEntityAggregate.FindSet(true, false) then begin
            if EnvironmentInformation.IsSaaS() then
                if SalesInvoiceEntityAggregate.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                    Session.LogMessage('0000GAQ', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradeSalesInvoiceShortcutDimension', SalesInvoiceEntityAggregate.TableName(), SalesInvoiceEntityAggregate.Count()), Verbosity::Warning,
                    DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                    exit;
                end;
            repeat
                if SalesInvoiceEntityAggregate.Posted then begin
                    SalesInvoiceHeader.SetLoadFields("No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if SalesInvoiceHeader.Get(SalesInvoiceEntityAggregate."No.") then begin
                        if SalesInvoiceHeader."Shortcut Dimension 1 Code" <> '' then
                            if SalesInvoiceHeader."Shortcut Dimension 1 Code" <> SalesInvoiceEntityAggregate."Shortcut Dimension 1 Code" then begin
                                SalesInvoiceEntityAggregate."Shortcut Dimension 1 Code" := SalesInvoiceHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if SalesInvoiceHeader."Shortcut Dimension 2 Code" <> '' then
                            if SalesInvoiceHeader."Shortcut Dimension 2 Code" <> SalesInvoiceEntityAggregate."Shortcut Dimension 2 Code" then begin
                                SalesInvoiceEntityAggregate."Shortcut Dimension 2 Code" := SalesInvoiceHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then
                            SalesInvoiceEntityAggregate.Modify();
                    end;
                end else begin
                    SalesHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesInvoiceEntityAggregate."No.") then begin
                        if SalesHeader."Shortcut Dimension 1 Code" <> '' then
                            if SalesHeader."Shortcut Dimension 1 Code" <> SalesInvoiceEntityAggregate."Shortcut Dimension 1 Code" then begin
                                SalesInvoiceEntityAggregate."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if SalesHeader."Shortcut Dimension 2 Code" <> '' then
                            if SalesHeader."Shortcut Dimension 2 Code" <> SalesInvoiceEntityAggregate."Shortcut Dimension 2 Code" then begin
                                SalesInvoiceEntityAggregate."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then
                            SalesInvoiceEntityAggregate.Modify();
                    end;
                end;
            until SalesInvoiceEntityAggregate.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesInvoiceShortcutDimensionsUpgradeTag());
    end;

    procedure UpgradePurchInvoiceShortcutDimension()
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchInvoiceShortcutDimensionsUpgradeTag()) then
            exit;

        PurchInvEntityAggregate.SetLoadFields(Id, "No.", Posted, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if PurchInvEntityAggregate.FindSet(true, false) then begin
            if EnvironmentInformation.IsSaaS() then
                if PurchInvEntityAggregate.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                    Session.LogMessage('0000GAR', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradePurchInvoiceShortcutDimension', PurchInvEntityAggregate.TableName(), PurchInvEntityAggregate.Count()), Verbosity::Warning,
                    DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                    exit;
                end;
            repeat
                if PurchInvEntityAggregate.Posted then begin
                    PurchInvHeader.SetLoadFields("No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if PurchInvHeader.Get(PurchInvEntityAggregate."No.") then begin
                        if PurchInvHeader."Shortcut Dimension 1 Code" <> '' then
                            if PurchInvHeader."Shortcut Dimension 1 Code" <> PurchInvEntityAggregate."Shortcut Dimension 1 Code" then begin
                                PurchInvEntityAggregate."Shortcut Dimension 1 Code" := PurchInvHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if PurchInvHeader."Shortcut Dimension 2 Code" <> '' then
                            if PurchInvHeader."Shortcut Dimension 2 Code" <> PurchInvEntityAggregate."Shortcut Dimension 2 Code" then begin
                                PurchInvEntityAggregate."Shortcut Dimension 2 Code" := PurchInvHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then
                            PurchInvEntityAggregate.Modify();
                    end;
                end else begin
                    PurchaseHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchInvEntityAggregate."No.") then begin
                        if PurchaseHeader."Shortcut Dimension 1 Code" <> '' then
                            if PurchaseHeader."Shortcut Dimension 1 Code" <> PurchInvEntityAggregate."Shortcut Dimension 1 Code" then begin
                                PurchInvEntityAggregate."Shortcut Dimension 1 Code" := PurchaseHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if PurchaseHeader."Shortcut Dimension 2 Code" <> '' then
                            if PurchaseHeader."Shortcut Dimension 2 Code" <> PurchInvEntityAggregate."Shortcut Dimension 2 Code" then begin
                                PurchInvEntityAggregate."Shortcut Dimension 2 Code" := PurchaseHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then
                            PurchInvEntityAggregate.Modify();
                    end;
                end;
            until PurchInvEntityAggregate.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPurchInvoiceShortcutDimensionsUpgradeTag());
    end;

    procedure UpgradePurchaseOrderShortcutDimension()
    var
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        PurchaseHeader: Record "Purchase Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPurchaseOrderShortcutDimensionsUpgradeTag()) then
            exit;

        PurchaseOrderEntityBuffer.SetLoadFields(Id, "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if PurchaseOrderEntityBuffer.FindSet(true, false) then begin
            if EnvironmentInformation.IsSaaS() then
                if PurchaseOrderEntityBuffer.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                    Session.LogMessage('0000GAS', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradePurchaseOrderShortcutDimension', PurchaseOrderEntityBuffer.TableName(), PurchaseOrderEntityBuffer.Count()), Verbosity::Warning,
                    DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                    exit;
                end;
            repeat
                PurchaseHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderEntityBuffer."No.") then begin
                    if PurchaseHeader."Shortcut Dimension 1 Code" <> '' then
                        if PurchaseHeader."Shortcut Dimension 1 Code" <> PurchaseOrderEntityBuffer."Shortcut Dimension 1 Code" then begin
                            PurchaseOrderEntityBuffer."Shortcut Dimension 1 Code" := PurchaseHeader."Shortcut Dimension 1 Code";
                            Modified := true;
                        end;
                    if PurchaseHeader."Shortcut Dimension 2 Code" <> '' then
                        if PurchaseHeader."Shortcut Dimension 2 Code" <> PurchaseOrderEntityBuffer."Shortcut Dimension 2 Code" then begin
                            PurchaseOrderEntityBuffer."Shortcut Dimension 2 Code" := PurchaseHeader."Shortcut Dimension 2 Code";
                            Modified := true;
                        end;
                    if Modified then
                        PurchaseOrderEntityBuffer.Modify();
                end;
            until PurchaseOrderEntityBuffer.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPurchaseOrderShortcutDimensionsUpgradeTag());
    end;

    procedure UpgradeSalesOrderShortcutDimension()
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesHeader: Record "Sales Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesOrderShortcutDimensionsUpgradeTag()) then
            exit;

        SalesOrderEntityBuffer.SetLoadFields(Id, "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if SalesOrderEntityBuffer.FindSet(true, false) then begin
            if EnvironmentInformation.IsSaaS() then
                if SalesOrderEntityBuffer.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                    Session.LogMessage('0000GAT', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradeSalesOrderShortcutDimension', SalesOrderEntityBuffer.TableName(), SalesOrderEntityBuffer.Count()), Verbosity::Warning,
                    DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                    exit;
                end;
            repeat
                SalesHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                if SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderEntityBuffer."No.") then begin
                    if SalesHeader."Shortcut Dimension 1 Code" <> '' then
                        if SalesHeader."Shortcut Dimension 1 Code" <> SalesOrderEntityBuffer."Shortcut Dimension 1 Code" then begin
                            SalesOrderEntityBuffer."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                            Modified := true;
                        end;
                    if SalesHeader."Shortcut Dimension 2 Code" <> '' then
                        if SalesHeader."Shortcut Dimension 2 Code" <> SalesOrderEntityBuffer."Shortcut Dimension 2 Code" then begin
                            SalesOrderEntityBuffer."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                            Modified := true;
                        end;
                    if Modified then
                        SalesOrderEntityBuffer.Modify();
                end;
            until SalesOrderEntityBuffer.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesOrderShortcutDimensionsUpgradeTag());
    end;

    procedure UpgradeSalesQuoteShortcutDimension()
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesHeader: Record "Sales Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesQuoteShortcutDimensionsUpgradeTag()) then
            exit;

        SalesQuoteEntityBuffer.SetLoadFields(Id, "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if SalesQuoteEntityBuffer.FindSet(true, false) then begin
            if EnvironmentInformation.IsSaaS() then
                if SalesQuoteEntityBuffer.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                    Session.LogMessage('0000GAU', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradeSalesQuoteShortcutDimension', SalesQuoteEntityBuffer.TableName(), SalesQuoteEntityBuffer.Count()), Verbosity::Warning,
                    DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                    exit;
                end;
            repeat
                SalesHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                if SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuoteEntityBuffer."No.") then begin
                    if SalesHeader."Shortcut Dimension 1 Code" <> '' then
                        if SalesHeader."Shortcut Dimension 1 Code" <> SalesQuoteEntityBuffer."Shortcut Dimension 1 Code" then begin
                            SalesQuoteEntityBuffer."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                            Modified := true;
                        end;
                    if SalesHeader."Shortcut Dimension 2 Code" <> '' then
                        if SalesHeader."Shortcut Dimension 2 Code" <> SalesQuoteEntityBuffer."Shortcut Dimension 2 Code" then begin
                            SalesQuoteEntityBuffer."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                            Modified := true;
                        end;
                    if Modified then
                        SalesQuoteEntityBuffer.Modify();
                end;
            until SalesQuoteEntityBuffer.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesQuoteShortcutDimensionsUpgradeTag());
    end;

    procedure UpgradeSalesCrMemoShortcutDimension()
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        EnvironmentInformation: Codeunit "Environment Information";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSalesCrMemoShortcutDimensionsUpgradeTag()) then
            exit;

        SalesCrMemoEntityBuffer.SetLoadFields(Id, "No.", Posted, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if SalesCrMemoEntityBuffer.FindSet(true, false) then begin
            if EnvironmentInformation.IsSaaS() then
                if SalesCrMemoEntityBuffer.Count() > GetSafeRecordCountForSaaSUpgrade() then begin
                    Session.LogMessage('0000GAV', StrSubstNo(UpgradeSkippedDueToManyRecordsLbl, 'UpgradeSalesCrMemoShortcutDimension', SalesCrMemoEntityBuffer.TableName(), SalesCrMemoEntityBuffer.Count()), Verbosity::Warning,
                    DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                    exit;
                end;
            repeat
                if SalesCrMemoEntityBuffer.Posted then begin
                    SalesCrMemoHeader.SetLoadFields("No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if SalesCrMemoHeader.Get(SalesCrMemoEntityBuffer."No.") then begin
                        if SalesCrMemoHeader."Shortcut Dimension 1 Code" <> '' then
                            if SalesCrMemoHeader."Shortcut Dimension 1 Code" <> SalesCrMemoEntityBuffer."Shortcut Dimension 1 Code" then begin
                                SalesCrMemoEntityBuffer."Shortcut Dimension 1 Code" := SalesCrMemoHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if SalesCrMemoHeader."Shortcut Dimension 2 Code" <> '' then
                            if SalesCrMemoHeader."Shortcut Dimension 2 Code" <> SalesCrMemoEntityBuffer."Shortcut Dimension 2 Code" then begin
                                SalesCrMemoEntityBuffer."Shortcut Dimension 2 Code" := SalesCrMemoHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then
                            SalesCrMemoEntityBuffer.Modify();
                    end;
                end else begin
                    SalesHeader.SetLoadFields("No.", "Document Type", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                    if SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesCrMemoEntityBuffer."No.") then begin
                        if SalesHeader."Shortcut Dimension 1 Code" <> '' then
                            if SalesHeader."Shortcut Dimension 1 Code" <> SalesCrMemoEntityBuffer."Shortcut Dimension 1 Code" then begin
                                SalesCrMemoEntityBuffer."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
                                Modified := true;
                            end;
                        if SalesHeader."Shortcut Dimension 2 Code" <> '' then
                            if SalesHeader."Shortcut Dimension 2 Code" <> SalesCrMemoEntityBuffer."Shortcut Dimension 2 Code" then begin
                                SalesCrMemoEntityBuffer."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
                                Modified := true;
                            end;
                        if Modified then
                            SalesCrMemoEntityBuffer.Modify();
                    end;
                end;
            until SalesCrMemoEntityBuffer.Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSalesCrMemoShortcutDimensionsUpgradeTag());
    end;

    local procedure GetSafeRecordCountForSaaSUpgrade(): Integer
    begin
        exit(300000);
    end;
}