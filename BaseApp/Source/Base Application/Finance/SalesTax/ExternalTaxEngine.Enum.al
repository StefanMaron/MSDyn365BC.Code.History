namespace Microsoft.Finance.SalesTax;

enum 399 "External Tax Engine" implements "External Tax Engine"
{
    Extensible = true;
    value(0; Default)
    {
        Implementation = "External Tax Engine" = ExternalTaxEngineDefault;
    }
}