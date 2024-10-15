#if not CLEAN19
codeunit 134603 "Report Sales Promotion Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('ReportHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestInfoMsgWhenNoSalesPromotionIsAvailable()
    var
        SalesPromotion: Report "Sales Promotion";
    begin
        // [SCENARIO] if the report has no values then an info message is shown to the user
        ClearTableItem();
        SalesPromotion.RunModal();
    end;

    [Test]
    [HandlerFunctions('ReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestNoInfoMsgWhenSalesPromotionIsAvailable()
    var
        SalesPromotion: Report "Sales Promotion";
    begin
        // [SCENARIO] if the report has values then NO info message is shown to the user
        addValuesIntoItemAndSalesPrice();
        SalesPromotion.RunModal();
    end;

    local procedure addValuesIntoItemAndSalesPrice()
    var
        SalesPrice: Record "Sales Price";
        Item: Record "Item";
        ItemNo: Text;
    begin
        ItemNo := 'test-item1010';

        Item."No." := ItemNo;
        Item.Description := 'test item';
        Item."Unit Price" := 1000;
        Item.Insert();

        SalesPrice."Item No." := ItemNo;
        SalesPrice.Insert();
    end;

    local procedure ClearTableSalesPrice()
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice.DeleteAll();
    end;

    local procedure ClearTableItem()
    var
        Item: Record "Item";
    begin
        Item.DeleteAll();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandler(var SalesPromotion: TestRequestPage "Sales Promotion")
    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
    begin
        SalesPromotion.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text)
    var
        InfoMsg: Label 'No sales promotions were found';
    begin
        if (Msg <> InfoMsg) then
            Error('The following info message was expected: %1', InfoMsg);
    end;
}
#endif
