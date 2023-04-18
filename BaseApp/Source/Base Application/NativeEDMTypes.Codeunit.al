#if not CLEAN20
codeunit 2801 "Native - EDM Types"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
        UpdateEDMTypes();
    end;

    var
        DummySalesLine: Record "Sales Line";

    [Scope('OnPrem')]
    procedure UpdateEDMTypes()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        GraphMgtGeneralTools.InsertOrUpdateODataType(
          'NATIVE-SALESINVOICE-LINE', 'Native Sales Invoice Lines', GetSalesLineEDM("Sales Document Type"::Invoice.AsInteger()));
        GraphMgtGeneralTools.InsertOrUpdateODataType(
          'NATIVE-SALESQUOTE-LINE', 'Native Sales Quote Lines', GetSalesLineEDM("Sales Document Type"::Quote.AsInteger()));
        GraphMgtGeneralTools.InsertOrUpdateODataType(
          'NATIVE-SALESDOCUMENT-COUPON', 'Native Sales Document Coupons', GetSalesCouponEDM());
        GraphMgtGeneralTools.InsertOrUpdateODataType(
          'NATIVE-ATTACHMENT', 'Native Attachments', GetAttachmentEDM());
    end;

    procedure GetSalesLineEDM(DocumentType: Option): Text
    var
        NativeSetupAPIs: Codeunit "Native - Setup APIs";
        EDM: Text;
    begin
        case DocumentType of
            DummySalesLine."Document Type"::Invoice.AsInteger():
                EDM := '<ComplexType Name="' + NativeSetupAPIs.GetAPIPrefix() + 'SalesInvoiceLines">';
            DummySalesLine."Document Type"::Quote.AsInteger():
                EDM := '<ComplexType Name="' + NativeSetupAPIs.GetAPIPrefix() + 'SalesQuoteLines">';
        end;

        EDM += '<Property Name="sequence" Type="Edm.Int32" Nullable="false" />' +
          '<Property Name="itemId" Type="Edm.Guid" Nullable="false" />' +
          '<Property Name="description" Type="Edm.String" MaxLength="' +
          Format(MaxStrLen(DummySalesLine.Description)) + '" Nullable="false" />' +
          '<Property Name="quantity" Type="Edm.Decimal" Nullable="false" />' +
          '<Property Name="unitPrice" Type="Edm.Decimal" Nullable="false" />' +
          '<Property Name="lineDiscountCalculation" Type="Edm.String" Nullable="true" />' +
          '<Property Name="lineDiscountValue" Type="Edm.Decimal" Nullable="false" />' +
          '<Property Name="taxable" Type="Edm.Boolean" Nullable="false" />' +
          '<Property Name="taxGroupId" Type="Edm.Guid" Nullable="false" />' +
          '<Property Name="lineAmount" Type="Edm.Decimal" Nullable="false" />' +
          '<Property Name="amountExcludingTax" Type="Edm.Decimal" Nullable="false" />' +
          '<Property Name="amountIncludingTax" Type="Edm.Decimal" Nullable="false" />' +
          '<Property Name="invoiceDiscountAmount" Type="Edm.Decimal" Nullable="false" />' +
          '<Property Name="taxPercent" Type="Edm.Decimal" Nullable="false" />' +
          '<Property Name="totalTaxAmount" Type="Edm.Decimal" Nullable="false" />' +
          '</ComplexType>';

        exit(EDM);
    end;

    [Scope('OnPrem')]
    procedure ParseSalesLinesJSON(DocumentType: Option; SalesLinesCollectionJSON: Text; var TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary; DocumentId: Guid)
    var
        JSONManagement: Codeunit "JSON Management";
        LineJsonObject: DotNet JObject;
        I: Integer;
        NumberOfLines: Integer;
    begin
        TempSalesInvoiceLineAggregate.Reset();
        TempSalesInvoiceLineAggregate.DeleteAll();
        JSONManagement.InitializeCollection(SalesLinesCollectionJSON);
        NumberOfLines := JSONManagement.GetCollectionCount();

        for I := 1 to NumberOfLines do begin
            JSONManagement.GetJObjectFromCollectionByIndex(LineJsonObject, I - 1);
            ParseSalesLineJSON(DocumentType, LineJsonObject, TempSalesInvoiceLineAggregate);
            TempSalesInvoiceLineAggregate."Document Id" := DocumentId;
            TempSalesInvoiceLineAggregate.Insert(true);
        end;
    end;

    procedure WriteSalesLinesJSON(var TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary): Text
    var
        SalesLineJSON: Text;
        SalesLinesArrayJSON: Text;
    begin
        if TempSalesInvoiceLineAggregate.FindSet() then
            repeat
                SalesLineJSON := SalesLineToJSON(TempSalesInvoiceLineAggregate);

                if SalesLinesArrayJSON <> '' then
                    SalesLinesArrayJSON := StrSubstNo('%1,%2', SalesLinesArrayJSON, SalesLineJSON)
                else
                    SalesLinesArrayJSON := StrSubstNo('%1', SalesLineJSON);
            until TempSalesInvoiceLineAggregate.Next() = 0;

        exit(StrSubstNo('[%1]', SalesLinesArrayJSON));
    end;

    [Scope('OnPrem')]
    procedure ParseSalesLineJSON(DocumentType: Option; JsonObject: DotNet JObject; var TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary)
    var
        Item: Record Item;
        SalesLineRecordRef: RecordRef;
        TargetFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
    begin
        Clear(TempSalesInvoiceLineAggregate);
        SalesLineRecordRef.GetTable(TempSalesInvoiceLineAggregate);

        GetFieldFromJSONAndRegisterFieldSet(
          JsonObject, 'sequence', TempSalesInvoiceLineAggregate.FieldNo("Line No."), SalesLineRecordRef);
        if GetFieldFromJSON(JsonObject, 'itemId', TempSalesInvoiceLineAggregate.FieldNo("Item Id"), SalesLineRecordRef) then begin
            TargetFieldRef := SalesLineRecordRef.Field(TempSalesInvoiceLineAggregate.FieldNo(Type));
            TargetFieldRef.Value := TempSalesInvoiceLineAggregate.Type::Item;

            SourceFieldRef := SalesLineRecordRef.Field(TempSalesInvoiceLineAggregate.FieldNo("Item Id"));
            Item.GetBySystemId(Format(SourceFieldRef.Value));
            TargetFieldRef := SalesLineRecordRef.Field(TempSalesInvoiceLineAggregate.FieldNo("No."));
            TargetFieldRef.Value := Item."No.";
        end;

        GetFieldFromJSONAndRegisterFieldSet(
          JsonObject, 'description', TempSalesInvoiceLineAggregate.FieldNo(Description), SalesLineRecordRef);
        GetFieldFromJSONAndRegisterFieldSet(
          JsonObject, 'quantity', TempSalesInvoiceLineAggregate.FieldNo(Quantity), SalesLineRecordRef);
        GetFieldFromJSONAndRegisterFieldSet(
          JsonObject, 'unitPrice', TempSalesInvoiceLineAggregate.FieldNo("Unit Price"), SalesLineRecordRef);

        if not ProcessTaxableProperty(JsonObject, TempSalesInvoiceLineAggregate.FieldNo("Tax Id"), SalesLineRecordRef) then
            GetFieldFromJSONAndRegisterFieldSet(
              JsonObject, 'taxGroupId', TempSalesInvoiceLineAggregate.FieldNo("Tax Id"), SalesLineRecordRef);

        GetFieldFromJSONAndRegisterFieldSet(
          JsonObject, 'lineDiscountCalculation', TempSalesInvoiceLineAggregate.FieldNo("Line Discount Calculation"), SalesLineRecordRef);
        GetFieldFromJSONAndRegisterFieldSet(
          JsonObject, 'lineDiscountValue', TempSalesInvoiceLineAggregate.FieldNo("Line Discount Value"), SalesLineRecordRef);
        case DocumentType of
            "Sales Document Type"::Quote.AsInteger():
                GetFieldFromJSONAndRegisterFieldSet(
                  JsonObject, 'shipmentDate', TempSalesInvoiceLineAggregate.FieldNo("Shipment Date"), SalesLineRecordRef);
        end;

        // Get Read Only Fields
        GetFieldFromJSON(
          JsonObject, 'lineAmount', TempSalesInvoiceLineAggregate.FieldNo("Line Amount"), SalesLineRecordRef);
        GetFieldFromJSON(
          JsonObject, 'amountIncludingTax', TempSalesInvoiceLineAggregate.FieldNo("Line Amount Including Tax"), SalesLineRecordRef);
        GetFieldFromJSON(
          JsonObject, 'amountExcludingTax', TempSalesInvoiceLineAggregate.FieldNo("Line Amount Excluding Tax"), SalesLineRecordRef);
        GetFieldFromJSON(
          JsonObject, 'invoiceDiscountAmount', TempSalesInvoiceLineAggregate.FieldNo("Inv. Discount Amount"), SalesLineRecordRef);
        GetFieldFromJSON(JsonObject, 'totalTaxAmount', TempSalesInvoiceLineAggregate.FieldNo("Tax Amount"), SalesLineRecordRef);
        GetFieldFromJSON(JsonObject, 'taxPercent', TempSalesInvoiceLineAggregate.FieldNo("VAT %"), SalesLineRecordRef);

        SalesLineRecordRef.SetTable(TempSalesInvoiceLineAggregate);
        TempSalesInvoiceLineAggregate.UpdateLineDiscounts();
    end;

    procedure SalesLineToJSON(var TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary): Text
    var
        JSONManagement: Codeunit "JSON Management";
        SalesLineRecordRef: RecordRef;
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        SalesLineRecordRef.GetTable(TempSalesInvoiceLineAggregate);
        WriteFieldToJSON(JsonObject, 'sequence', TempSalesInvoiceLineAggregate.FieldNo("Line No."), SalesLineRecordRef);
        WriteFieldToJSON(JsonObject, 'itemId', TempSalesInvoiceLineAggregate.FieldNo("Item Id"), SalesLineRecordRef);
        WriteFieldToJSON(JsonObject, 'description', TempSalesInvoiceLineAggregate.FieldNo(Description), SalesLineRecordRef);
        WriteFieldToJSON(JsonObject, 'unitOfMeasureId', TempSalesInvoiceLineAggregate.FieldNo("Unit of Measure Id"), SalesLineRecordRef);
        WriteFieldToJSON(JsonObject, 'quantity', TempSalesInvoiceLineAggregate.FieldNo(Quantity), SalesLineRecordRef);
        WriteFieldToJSON(JsonObject, 'unitPrice', TempSalesInvoiceLineAggregate.FieldNo("Unit Price"), SalesLineRecordRef);
        WriteFieldToJSON(
          JsonObject, 'lineDiscountCalculation', TempSalesInvoiceLineAggregate.FieldNo("Line Discount Calculation"), SalesLineRecordRef);
        WriteFieldToJSON(JsonObject, 'lineDiscountValue', TempSalesInvoiceLineAggregate.FieldNo("Line Discount Value"), SalesLineRecordRef);

        JSONManagement.AddJPropertyToJObject(JsonObject, 'taxable', GetTaxableFromTaxGroup(TempSalesInvoiceLineAggregate."Tax Id"));
        WriteFieldToJSON(JsonObject, 'taxGroupId', TempSalesInvoiceLineAggregate.FieldNo("Tax Id"), SalesLineRecordRef);
        WriteFieldToJSON(JsonObject, 'taxPercent', TempSalesInvoiceLineAggregate.FieldNo("VAT %"), SalesLineRecordRef);
        WriteFieldToJSON(JsonObject, 'lineAmount', TempSalesInvoiceLineAggregate.FieldNo("Line Amount"), SalesLineRecordRef);
        WriteFieldToJSON(
          JsonObject, 'amountIncludingTax', TempSalesInvoiceLineAggregate.FieldNo("Line Amount Including Tax"), SalesLineRecordRef);
        WriteFieldToJSON(
          JsonObject, 'amountExcludingTax', TempSalesInvoiceLineAggregate.FieldNo("Line Amount Excluding Tax"), SalesLineRecordRef);
        WriteFieldToJSON(
          JsonObject, 'invoiceDiscountAmount', TempSalesInvoiceLineAggregate.FieldNo("Inv. Discount Amount"), SalesLineRecordRef);
        WriteFieldToJSON(JsonObject, 'totalTaxAmount', TempSalesInvoiceLineAggregate.FieldNo("Tax Amount"), SalesLineRecordRef);
        exit(JsonObject.ToString());
    end;

    procedure GetSalesCouponEDM(): Text
    var
        DummyO365CouponClaim: Record "O365 Coupon Claim";
        NativeSetupAPIs: Codeunit "Native - Setup APIs";
    begin
        exit(
          '<ComplexType Name="' + NativeSetupAPIs.GetAPIPrefix() + 'SalesDocumentCoupons">' +
          '<Property Name="claimId" Type="Edm.String" Nullable="false" />' +
          '<Property Name="usage" Type="Edm.String" Nullable="true" />' +
          '<Property Name="offer" Type="Edm.String" MaxLength="' +
          Format(MaxStrLen(DummyO365CouponClaim.Offer)) + '" Nullable="true" />' +
          '<Property Name="terms" Type="Edm.String" MaxLength="' +
          Format(MaxStrLen(DummyO365CouponClaim.Terms)) + '" Nullable="true" />' +
          '<Property Name="code" Type="Edm.String" MaxLength="' +
          Format(MaxStrLen(DummyO365CouponClaim.Code)) + '" Nullable="true" />' +
          '<Property Name="expiration" Type="Edm.Date" Nullable="true" />' +
          '<Property Name="discountValue" Type="Edm.Decimal" Nullable="true" />' +
          '<Property Name="discountType" Type="Edm.String" Nullable="true" />' +
          '<Property Name="amount" Type="Edm.String" Nullable="true" />' +
          '</ComplexType>');
    end;

    [Scope('OnPrem')]
    procedure ParseCouponsJSON(ContactGraphId: Text[250]; DocumentType: Option; DocumentNo: Code[20]; CouponsJSON: Text)
    var
        O365CouponClaimDocLink: Record "O365 Coupon Claim Doc. Link";
        JSONManagement: Codeunit "JSON Management";
        NativeCoupons: Codeunit "Native - Coupons";
        LineJsonObject: DotNet JObject;
        I: Integer;
        NumberOfLines: Integer;
    begin
        O365CouponClaimDocLink.SetRange("Document Type", DocumentType);
        O365CouponClaimDocLink.SetRange("Document No.", DocumentNo);
        O365CouponClaimDocLink.DeleteAll();
        JSONManagement.InitializeCollection(CouponsJSON);
        NumberOfLines := JSONManagement.GetCollectionCount();

        if NumberOfLines = 0 then
            exit;

        for I := 1 to NumberOfLines do begin
            JSONManagement.GetJObjectFromCollectionByIndex(LineJsonObject, I - 1);
            O365CouponClaimDocLink.Reset();
            ParseCouponJSON(LineJsonObject, O365CouponClaimDocLink);
            O365CouponClaimDocLink."Graph Contact ID" := ContactGraphId;
            O365CouponClaimDocLink."Document Type" := "Sales Document Type".FromInteger(DocumentType);
            O365CouponClaimDocLink."Document No." := DocumentNo;

            NativeCoupons.CheckThatCouponCanBeAppliedToInvoice(O365CouponClaimDocLink);
            NativeCoupons.CheckIfCouponCanBeUsed(O365CouponClaimDocLink);

            O365CouponClaimDocLink.Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure ParseCouponJSON(JsonObject: DotNet JObject; var O365CouponClaimDocLink: Record "O365 Coupon Claim Doc. Link")
    var
        CouponLinkRecordRef: RecordRef;
    begin
        CouponLinkRecordRef.GetTable(O365CouponClaimDocLink);
        GetFieldFromJSON(JsonObject, 'claimId', O365CouponClaimDocLink.FieldNo("Claim ID"), CouponLinkRecordRef);
        CouponLinkRecordRef.SetTable(O365CouponClaimDocLink);
    end;

    procedure WriteCouponsJSON(DocumentType: Option; DocumentNo: Code[20]): Text
    var
        O365CouponClaimDocLink: Record "O365 Coupon Claim Doc. Link";
        O365CouponClaim: Record "O365 Coupon Claim";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        JsonArray: DotNet JArray;
        O365CouponClaimDocLinkRecordRef: RecordRef;
    begin
        JSONManagement.InitializeEmptyCollection();
        JSONManagement.GetJsonArray(JsonArray);

        O365CouponClaimDocLink.SetRange("Document Type", DocumentType);
        O365CouponClaimDocLink.SetRange("Document No.", DocumentNo);
        if O365CouponClaimDocLink.FindSet() then
            repeat
                O365CouponClaim.Get(O365CouponClaimDocLink."Claim ID", O365CouponClaimDocLink."Graph Contact ID");
                O365CouponClaimDocLinkRecordRef.GetTable(O365CouponClaim);
                CouponToJSON(O365CouponClaimDocLinkRecordRef, JsonObject);
                JSONManagement.AddJObjectToJArray(JsonArray, JsonObject);
            until O365CouponClaimDocLink.Next() = 0;

        exit(JSONManagement.WriteCollectionToString());
    end;

    procedure WritePostedCouponsJSON(PostedInvoiceNo: Code[20]): Text
    var
        O365PostedCouponClaim: Record "O365 Posted Coupon Claim";
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        JsonArray: DotNet JArray;
        O365PostedCouponClaimRecordRef: RecordRef;
    begin
        JSONManagement.InitializeEmptyCollection();
        JSONManagement.GetJsonArray(JsonArray);

        O365PostedCouponClaim.SetRange("Sales Invoice No.", PostedInvoiceNo);
        if O365PostedCouponClaim.FindSet() then
            repeat
                O365PostedCouponClaimRecordRef.GetTable(O365PostedCouponClaim);
                CouponToJSON(O365PostedCouponClaimRecordRef, JsonObject);
                JSONManagement.AddJObjectToJArray(JsonArray, JsonObject);
            until O365PostedCouponClaim.Next() = 0;

        exit(JSONManagement.WriteCollectionToString());
    end;

    [Scope('OnPrem')]
    procedure CouponToJSON(var CouponRecordRef: RecordRef; var JsonObject: DotNet JObject)
    var
        DummyO365CouponClaim: Record "O365 Coupon Claim";
        JSONManagement: Codeunit "JSON Management";
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        WriteFieldToJSON(JsonObject, 'claimId', DummyO365CouponClaim.FieldNo("Claim ID"), CouponRecordRef);
        WriteFieldToJSON(JsonObject, 'graphContactId', DummyO365CouponClaim.FieldNo("Graph Contact ID"), CouponRecordRef);
        WriteFieldToJSON(JsonObject, 'usage', DummyO365CouponClaim.FieldNo(Usage), CouponRecordRef);
        WriteFieldToJSON(JsonObject, 'offer', DummyO365CouponClaim.FieldNo(Offer), CouponRecordRef);
        WriteFieldToJSON(JsonObject, 'terms', DummyO365CouponClaim.FieldNo(Terms), CouponRecordRef);
        WriteFieldToJSON(JsonObject, 'code', DummyO365CouponClaim.FieldNo(Code), CouponRecordRef);
        WriteFieldToJSON(JsonObject, 'expiration', DummyO365CouponClaim.FieldNo(Expiration), CouponRecordRef);
        WriteFieldToJSON(JsonObject, 'discountValue', DummyO365CouponClaim.FieldNo("Discount Value"), CouponRecordRef);
        WriteFieldToJSON(JsonObject, 'discountType', DummyO365CouponClaim.FieldNo("Discount Type"), CouponRecordRef);
        WriteFieldToJSON(JsonObject, 'amount', DummyO365CouponClaim.FieldNo("Amount Text"), CouponRecordRef);
    end;

    procedure GetAttachmentEDM(): Text
    var
        DummyAttachmentEntityBuffer: Record "Attachment Entity Buffer";
        NativeSetupAPIs: Codeunit "Native - Setup APIs";
    begin
        exit(
          '<ComplexType Name="' + NativeSetupAPIs.GetAPIPrefix() + 'DocumentAttachments">' +
          '<Property Name="id" Type="Edm.Guid" Nullable="false" />' +
          '<Property Name="fileName" Type="Edm.String" MaxLength="' +
          Format(MaxStrLen(DummyAttachmentEntityBuffer."File Name")) + '" Nullable="true" />' +
          '<Property Name="byteSize" Type="Edm.Int32" Nullable="true" />' +
          '</ComplexType>');
    end;

    [Scope('OnPrem')]
    procedure ParseAttachmentsJSON(AttachmentsCollectionJSON: Text; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; DocumentId: Guid)
    var
        JSONManagement: Codeunit "JSON Management";
        LineJsonObject: DotNet JObject;
        JsonLineIndex: Integer;
        NumberOfLines: Integer;
    begin
        TempAttachmentEntityBuffer.Reset();
        TempAttachmentEntityBuffer.DeleteAll();
        JSONManagement.InitializeCollection(AttachmentsCollectionJSON);
        NumberOfLines := JSONManagement.GetCollectionCount();

        for JsonLineIndex := 1 to NumberOfLines do begin
            JSONManagement.GetJObjectFromCollectionByIndex(LineJsonObject, JsonLineIndex - 1);
            ParseAttachmentJSON(LineJsonObject, TempAttachmentEntityBuffer);
            TempAttachmentEntityBuffer."Document Id" := DocumentId;
            if IsNullGuid(TempAttachmentEntityBuffer.Id) then
                TempAttachmentEntityBuffer.Id := CreateGuid();
            TempAttachmentEntityBuffer.Insert(true);
        end;
    end;

    procedure WriteAttachmentsJSON(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        JsonArray: DotNet JArray;
    begin
        JSONManagement.InitializeEmptyCollection();
        JSONManagement.GetJsonArray(JsonArray);

        if TempAttachmentEntityBuffer.FindSet() then
            repeat
                AttachmentToJSON(TempAttachmentEntityBuffer, JsonObject);
                JSONManagement.AddJObjectToJArray(JsonArray, JsonObject);
            until TempAttachmentEntityBuffer.Next() = 0;

        exit(JSONManagement.WriteCollectionToString());
    end;

    [Scope('OnPrem')]
    procedure ParseAttachmentJSON(JsonObject: DotNet JObject; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary)
    var
        AttachmentRecordRef: RecordRef;
    begin
        Clear(TempAttachmentEntityBuffer);
        AttachmentRecordRef.GetTable(TempAttachmentEntityBuffer);

        GetFieldFromJSONAndRegisterFieldSet(
          JsonObject, 'id', TempAttachmentEntityBuffer.FieldNo(Id), AttachmentRecordRef);

        // Get read only fields
        GetFieldFromJSON(
          JsonObject, 'fileName', TempAttachmentEntityBuffer.FieldNo("File Name"), AttachmentRecordRef);
        GetFieldFromJSON(
          JsonObject, 'byteSize', TempAttachmentEntityBuffer.FieldNo("Byte Size"), AttachmentRecordRef);

        AttachmentRecordRef.SetTable(TempAttachmentEntityBuffer);
    end;

    [Scope('OnPrem')]
    procedure AttachmentToJSON(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var JsonObject: DotNet JObject)
    var
        JSONManagement: Codeunit "JSON Management";
        AttachmentRecordRef: RecordRef;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        AttachmentRecordRef.GetTable(TempAttachmentEntityBuffer);
        WriteFieldToJSON(JsonObject, 'id', TempAttachmentEntityBuffer.FieldNo(Id), AttachmentRecordRef);
        WriteFieldToJSON(JsonObject, 'fileName', TempAttachmentEntityBuffer.FieldNo("File Name"), AttachmentRecordRef);
        WriteFieldToJSON(JsonObject, 'byteSize', TempAttachmentEntityBuffer.FieldNo("Byte Size"), AttachmentRecordRef);
    end;

    local procedure GetFieldFromJSONAndRegisterFieldSet(JsonObject: DotNet JObject; propertyName: Text; TargetFieldNumber: Integer; var TargetRecordRef: RecordRef): Boolean
    begin
        if not GetFieldFromJSON(JsonObject, propertyName, TargetFieldNumber, TargetRecordRef) then
            exit(false);

        exit(true);
    end;

    local procedure GetFieldFromJSON(JsonObject: DotNet JObject; propertyName: Text; TargetFieldNumber: Integer; var TargetRecordRef: RecordRef): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        TargetFieldRef: FieldRef;
        OriginalValue: Variant;
        CurrentValue: Variant;
    begin
        TargetFieldRef := TargetRecordRef.Field(TargetFieldNumber);

        OriginalValue := TargetFieldRef.Value;

        if not JSONManagement.GetPropertyValueFromJObjectByPathSetToFieldRef(JsonObject, propertyName, TargetFieldRef) then
            exit(false);

        CurrentValue := TargetFieldRef.Value;
        TargetFieldRef.Value := OriginalValue;
        TargetFieldRef.Validate(CurrentValue);

        exit(true);
    end;

    procedure GetFieldSetBufferWithAllFieldsSet(var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        DummySalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Line No."), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo(Type), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Item Id"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("No."), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo(Description), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Tax Id"), TempFieldBuffer);

        if GeneralLedgerSetup.UseVat() then
            RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("VAT Prod. Posting Group"), TempFieldBuffer)
        else
            RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Tax Group Code"), TempFieldBuffer);

        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo(Quantity), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Unit Price"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Line Discount Calculation"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Line Discount Value"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Line Discount Amount"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Line Discount %"), TempFieldBuffer);
        RegisterFieldSet(DummySalesInvoiceLineAggregate.FieldNo("Shipment Date"), TempFieldBuffer);
    end;

    local procedure WriteFieldToJSON(JsonObject: DotNet JObject; propertyName: Text; TargetFieldNumber: Integer; var TargetRecordRef: RecordRef): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        ValueVariant: Variant;
        TargetFieldRef: FieldRef;
        GuidValue: Guid;
        OptionNumber: Integer;
        IsNullValue: Boolean;
        DateTimeValue: DateTime;
    begin
        TargetFieldRef := TargetRecordRef.Field(TargetFieldNumber);
        ValueVariant := TargetFieldRef.Value;

        case TargetFieldRef.Type of
            FieldType::Guid:
                begin
                    GuidValue := TargetFieldRef.Value;
                    ValueVariant := LowerCase(GraphMgtGeneralTools.GetIdWithoutBrackets(GuidValue));
                end;
            FieldType::Option:
                begin
                    OptionNumber := TargetFieldRef.Value;
                    OptionNumber += 1;
                    ValueVariant := SelectStr(OptionNumber, TargetFieldRef.OptionMembers);
                end;
            FieldType::Datetime:
                begin
                    DateTimeValue := TargetFieldRef.Value;
                    IsNullValue := DateTimeValue = 0DT;
                end;
        end;

        if IsNullValue then
            JSONManagement.AddNullJPropertyToJObject(JsonObject, propertyName)
        else
            JSONManagement.AddJPropertyToJObject(JsonObject, propertyName, ValueVariant);

        exit(true);
    end;

    local procedure RegisterFieldSet(FieldNo: Integer; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        if TempFieldBuffer.FindLast() then
            LastOrderNo := TempFieldBuffer.Order + 1;

        Clear(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := DATABASE::"Sales Invoice Line Aggregate";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure ProcessTaxableProperty(var JsonObject: DotNet JObject; TargetFieldNumber: Integer; var TargetRecordRef: RecordRef): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        JSONManagement: Codeunit "JSON Management";
        Taxable: Boolean;
    begin
        if GeneralLedgerSetup.UseVat() then
            exit(false);

        if not JSONManagement.GetBoolPropertyValueFromJObjectByName(JsonObject, 'taxable', Taxable) then
            exit(false);

        ValidateTaxable(Taxable, TargetFieldNumber, TargetRecordRef);

        exit(true);
    end;

    local procedure ValidateTaxable(Taxable: Boolean; TargetFieldNumber: Integer; var TargetRecordRef: RecordRef): Boolean
    var
        TaxGroup: Record "Tax Group";
        TaxGroupIdFieldRef: FieldRef;
    begin
        if not GetTaxGroupFromTaxable(Taxable, TaxGroup) then
            exit(false);

        TaxGroupIdFieldRef := TargetRecordRef.Field(TargetFieldNumber);
        TaxGroupIdFieldRef.Validate(TaxGroup.SystemId);
        exit(true);
    end;

    procedure GetTaxGroupFromTaxable(Taxable: Boolean; var TaxGroup: Record "Tax Group"): Boolean
    var
        TaxSetup: Record "Tax Setup";
    begin
        if TaxSetup.Get() then
            if TaxSetup."Non-Taxable Tax Group Code" <> '' then
                if Taxable then
                    TaxGroup.SetFilter(Code, '<>%1', TaxSetup."Non-Taxable Tax Group Code")
                else
                    TaxGroup.SetFilter(Code, '%1', TaxSetup."Non-Taxable Tax Group Code");

        exit(TaxGroup.FindFirst());
    end;

    local procedure GetTaxableFromTaxGroup(TaxGroupID: Guid): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TaxableTaxGroup: Record "Tax Group";
        NonTaxableTaxGroup: Record "Tax Group";
    begin
        if GeneralLedgerSetup.UseVat() then
            exit(false);

        if IsNullGuid(TaxGroupID) then
            exit(true);

        GetTaxGroupFromTaxable(true, TaxableTaxGroup);
        if TaxableTaxGroup.SystemId = TaxGroupID then
            exit(true);

        GetTaxGroupFromTaxable(false, NonTaxableTaxGroup);
        exit(not (NonTaxableTaxGroup.SystemId = TaxGroupID));
    end;
}
#endif
