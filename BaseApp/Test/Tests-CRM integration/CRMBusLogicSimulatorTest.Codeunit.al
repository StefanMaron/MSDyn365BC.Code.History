codeunit 139184 "CRM Bus. Logic Simulator Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Mock]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        SalesOrderIsNotEditableErr: Label 'CRM Sales order is not editable.';
        ReadOnlyEntityCannotBeUpdatedErr: Label 'The entity cannot be updated because it is read-only.';
        InactiveInvoiceCannotBePaidErr: Label 'The invoice cannot be paid because it is not in active state.';
        PriceListLineAlreadyExistsErr: Label 'This product and unit combination has a price for this price list.';
        ProductIdMissingErr: Label 'The product id is missing.';
        ModifiedOnErr: Label 'ModifiedOn %1 should be bigger than CreatedOn %2';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ProductPriceLevelNeedsPriceLevelIDOnInsert()
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        with CRMProductpricelevel do begin
            Init();
            asserterror Insert();
            Assert.ExpectedError('Price List must have a value in CRM Productpricelevel');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ProductPriceLevelMustHaveProductIDOnInsert()
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        with CRMProductpricelevel do begin
            Init();
            PriceLevelId := CreateGuid();
            asserterror Insert();
            Assert.ExpectedError(ProductIdMissingErr);
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ProductPriceLevelMustHaveUniqueProductAndUoMOnInsert()
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        with CRMProductpricelevel do begin
            Init();
            ProductPriceLevelId := CreateGuid();
            PriceLevelId := CreateGuid();
            ProductId := CreateGuid();
            UoMId := CreateGuid();
            Amount := 1.0;
            Insert();

            // another line with the same pair of ProductId + UoMId
            ProductPriceLevelId := CreateGuid();
            Amount += 1;
            asserterror Insert();
            Assert.ExpectedError(PriceListLineAlreadyExistsErr);
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InvoiceDetailGetsBlankAmountsOnInsert()
    var
        CRMInvoicedetail: Record "CRM Invoicedetail";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        with CRMInvoicedetail do begin
            Init();
            BaseAmount := 1.0;
            ExtendedAmount := 2.0;
            Insert(); // handled by ValidateSalesInvoiceLineOnInsert
            TestField(BaseAmount, 0);
            TestField(ExtendedAmount, 0);
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CurrencyWithZeroExchangeRateFailsOnInsert()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        with CRMTransactioncurrency do begin
            TransactionCurrencyId := CreateGuid();
            ISOCurrencyCode := '12345';
            asserterror Insert(); // handled by ValidateCurrencyOnInsert
            Assert.ExpectedError('Exchange Rate must have a value in Dataverse Transactioncurrency');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesOrderShouldNotBeEditableIfSubmitted()
    var
        CRMSalesorder: Record "CRM Salesorder";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        with CRMSalesorder do begin
            SalesOrderId := CreateGuid();
            StateCode := StateCode::Submitted;
            LastBackofficeSubmit := 0D;
            Insert();

            LastBackofficeSubmit := Today;
            asserterror Modify(true);

            Assert.ExpectedError(SalesOrderIsNotEditableErr);
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesOrderAmountsShouldBeRecalculatedOnLineModify()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: array[2] of Record "CRM Salesorderdetail";
        DiscountPctAmount: Decimal;
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] the CRM Salesorder with one line
        CRMSalesorder.SalesOrderId := CreateGuid();
        CRMSalesorder.Insert();

        CRMSalesorderdetail[1].SalesOrderDetailId := CreateGuid();
        CRMSalesorderdetail[1].SalesOrderId := CRMSalesorder.SalesOrderId;
        CRMSalesorderdetail[1].Insert();

        // [GIVEN] the line contains volume and manual discounts
        with CRMSalesorderdetail[1] do begin
            Quantity := 10;
            ManualDiscountAmount := 400;
            VolumeDiscountAmount := 280;
            PricePerUnit := 4000;
            Tax := 5000;
            // [WHEN] Modify the order line
            Modify(); // recalc in onModify

            // [THEN] the line is recalculated: BaseAmount, ExtendedAmount
            TestField(BaseAmount, (PricePerUnit - VolumeDiscountAmount) * Quantity);
            TestField(ExtendedAmount, BaseAmount - ManualDiscountAmount + Tax);
        end;
        // [GIVEN] added the second line
        CRMSalesorderdetail[2] := CRMSalesorderdetail[1];
        CRMSalesorderdetail[2].SalesOrderDetailId := CreateGuid();
        CRMSalesorderdetail[2].Insert();

        // [WHEN] Quantity, ManualDiscountAmount, and Tax are changed in the 2nd line
        with CRMSalesorderdetail[2] do begin
            Quantity := 5;
            ManualDiscountAmount := 250;
            Tax := 3000;
            Modify(); // recalc in onModify

            // [THEN] the 2nd line is recalculated: BaseAmount, ExtendedAmount
            TestField(BaseAmount, (PricePerUnit - VolumeDiscountAmount) * Quantity);
            TestField(ExtendedAmount, BaseAmount - ManualDiscountAmount + Tax);
        end;

        // [THEN] the header is recalculated: TotalLineItemDiscountAmount, TotalLineItemAmount, TotalTax
        with CRMSalesorder do begin
            Find();
            TestField(
              TotalLineItemDiscountAmount,
              CRMSalesorderdetail[1].ManualDiscountAmount + CRMSalesorderdetail[2].ManualDiscountAmount);
            TestField(
              TotalLineItemAmount,
              CRMSalesorderdetail[1].BaseAmount + CRMSalesorderdetail[2].BaseAmount - TotalLineItemDiscountAmount);
            TestField(TotalTax, CRMSalesorderdetail[1].Tax + CRMSalesorderdetail[2].Tax);
            // [THEN] TotalAmount = TotalLineItemAmount + Total Tax, as no discounts and freight on the header
            TestField(TotalAmountLessFreight, TotalLineItemAmount);
            TestField(TotalDiscountAmount, TotalLineItemDiscountAmount);
            TestField(TotalAmount, TotalLineItemAmount + TotalTax);

            // [WHEN] add discounts and freight to the header
            DiscountAmount := 3500;
            FreightAmount := 1020;
            DiscountPercentage := 9;
            Modify(); // recalc in onModify

            // [THEN] TotalAmount includes discounts and freight
            DiscountPctAmount := Round(TotalLineItemAmount * DiscountPercentage / 100);
            TestField(TotalAmountLessFreight, TotalLineItemAmount - DiscountPctAmount - DiscountAmount);
            TestField(TotalDiscountAmount, TotalLineItemDiscountAmount + DiscountPctAmount + DiscountAmount);
            TestField(TotalAmount, TotalAmountLessFreight + FreightAmount + TotalTax);
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InvoiceIsReadOnlyIfStateIsPaid()
    var
        CRMInvoice: Record "CRM Invoice";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMInvoice.InvoiceId := CreateGuid();
        CRMInvoice.StateCode := CRMInvoice.StateCode::Paid;
        CRMInvoice.StatusCode := CRMInvoice.StatusCode::Partial;
        CRMInvoice.Insert();

        CRMInvoice.StatusCode := CRMInvoice.StatusCode::Complete;
        asserterror CRMInvoice.Modify();

        Assert.ExpectedError(ReadOnlyEntityCannotBeUpdatedErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InvoiceIsReadOnlyIfStateIsCancelled()
    var
        CRMInvoice: Record "CRM Invoice";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMInvoice.InvoiceId := CreateGuid();
        CRMInvoice.StateCode := CRMInvoice.StateCode::Canceled;
        CRMInvoice.StatusCode := CRMInvoice.StatusCode::Canceled;
        CRMInvoice.Insert();

        CRMInvoice.StateCode := CRMInvoice.StateCode::Paid;
        CRMInvoice.StatusCode := CRMInvoice.StatusCode::Complete;
        asserterror CRMInvoice.Modify();

        Assert.ExpectedError(InactiveInvoiceCannotBePaidErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMAccountModifiedOnDefinedOnModify()
    var
        CRMAccount: Record "CRM Account";
    begin
        // [SCENARIO] INSERT(TRUE) and MODIFY(TRUE) on CRM Account update "CreatedOn" and "ModifiedOn"
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMAccount.Init();
        CRMAccount.AccountId := CreateGuid();
        // [WHEN] CRMAccount.INSERT(TRUE)
        CRMAccount.Insert(true);

        // [THEN] CreatedOn = ModifiedOn, both are not blank
        CRMAccount.TestField(CreatedOn);
        CRMAccount.TestField(ModifiedOn, CRMAccount.CreatedOn);

        // [WHEN] CRMAccount.MODIFY(TRUE) (a bit later to see a difference between CreatedOn and ModifiedOn)
        Sleep(50);
        CRMAccount.Modify(true);

        // [THEN] ModifiedOn > CreatedOn, both are not blank
        CRMAccount.TestField(CreatedOn);
        if CRMAccount.CreatedOn >= CRMAccount.ModifiedOn then
            Error(
              StrSubstNo(
                ModifiedOnErr, Format(CRMAccount.ModifiedOn, 0, 9), Format(CRMAccount.CreatedOn, 0, 9)));
    end;
}

