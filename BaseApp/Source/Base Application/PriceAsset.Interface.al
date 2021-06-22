interface "Price Asset"
{
    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure GetNo(var PriceAsset: Record "Price Asset")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure GetId(var PriceAsset: Record "Price Asset")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure ValidateUnitOfMeasure(var PriceAsset: Record "Price Asset"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "Price Asset"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure IsLookupVariantOK(var PriceAsset: Record "Price Asset"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure IsAssetNoRequired(): Boolean;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure FillBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure FilterPriceLines(PriceAsset: Record "Price Asset"; var PriceListLine: Record "Price List Line") Result: Boolean;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>The list of assets in the TempPriceAsset buffer.</returns>
    procedure PutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>The list of assets in the TempPriceAsset buffer.</returns>
    procedure FillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
}