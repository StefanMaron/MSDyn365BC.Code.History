namespace Microsoft.Purchases.Document;

query 9063 "Count Purchase Orders"
{
    Caption = 'Count Purchase Orders';

    elements
    {
        dataitem(Purchase_Header; "Purchase Header")
        {
            DataItemTableFilter = "Document Type" = const(Order);
            filter(Completely_Received; "Completely Received")
            {
            }
            filter(Responsibility_Center; "Responsibility Center")
            {
            }
            filter(Status; Status)
            {
            }
            filter(Partially_Invoiced; "Partially Invoiced")
            {
            }
            column(Count_Orders)
            {
                Method = Count;
            }
        }
    }
}

