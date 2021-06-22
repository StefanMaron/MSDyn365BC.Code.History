interface "Price Source"
{
    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure GetNo(var PriceSource: Record "Price Source")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure GetId(var PriceSource: Record "Price Source")

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure IsLookupOK(var PriceSource: Record "Price Source"): Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure VerifyParent(var PriceSource: Record "Price Source") Result: Boolean

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure IsSourceNoAllowed() Result: Boolean;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="...">....</param>
    /// <returns>  .</returns>
    procedure GetGroupNo(PriceSource: Record "Price Source"): Code[20];
}