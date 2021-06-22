query 9060 "Count Sales Orders"
{
    Caption = 'Count Sales Orders';

    elements
    {
        dataitem(Sales_Header; "Sales Header")
        {
            DataItemTableFilter = "Document Type" = CONST(Order);
            filter(Status; Status)
            {
            }
            filter(Shipped; Shipped)
            {
            }
            filter(Completely_Shipped; "Completely Shipped")
            {
            }
            filter(Responsibility_Center; "Responsibility Center")
            {
            }
            filter(Shipped_Not_Invoiced; "Shipped Not Invoiced")
            {
            }
            filter(Ship; Ship)
            {
            }
            filter(Date_Filter; "Date Filter")
            {
            }
            filter(Late_Order_Shipping; "Late Order Shipping")
            {
            }
            filter(Shipment_Date; "Shipment Date")
            {
            }
            column(Count_Orders)
            {
                Method = Count;
            }
        }
    }
}

