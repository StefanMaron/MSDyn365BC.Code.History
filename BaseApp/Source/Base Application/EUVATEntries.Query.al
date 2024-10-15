query 141 "EU VAT Entries"
{
    Caption = 'EU VAT Entries';

    elements
    {
        dataitem(VAT_Entry; "VAT Entry")
        {
            DataItemTableFilter = Type = CONST(Sale);
            column(Base; Base)
            {
            }
            column(PostingDate; "Posting Date")
            {
            }
            column(Type; Type)
            {
            }
            column(EU_3_Party_Trade; "EU 3-Party Trade")
            {
            }
            column(VAT_Registration_No; "VAT Registration No.")
            {
            }
            column(EU_Service; "EU Service")
            {
            }
            column(Entry_No; "Entry No.")
            {
            }
            dataitem(Country_Region; "Country/Region")
            {
                DataItemLink = Code = VAT_Entry."Country/Region Code";
                SqlJoinType = InnerJoin;
                DataItemTableFilter = "EU Country/Region Code" = FILTER(<> '');
                column(Name; Name)
                {
                }
                column(EU_Country_Region_Code; "EU Country/Region Code")
                {
                }
                column(CountryCode; "Code")
                {
                }
            }
        }
    }
}

