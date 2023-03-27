USE [master]
GO
/****** Object:  Database [WholeSales]    Script Date: 1/14/2023 11:03:33 PM ******/
CREATE DATABASE [WholeSales]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'WholeSales', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\WholeSales.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'WholeSales_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\WholeSales_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [WholeSales] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [WholeSales].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [WholeSales] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [WholeSales] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [WholeSales] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [WholeSales] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [WholeSales] SET ARITHABORT OFF 
GO
ALTER DATABASE [WholeSales] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [WholeSales] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [WholeSales] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [WholeSales] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [WholeSales] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [WholeSales] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [WholeSales] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [WholeSales] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [WholeSales] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [WholeSales] SET  ENABLE_BROKER 
GO
ALTER DATABASE [WholeSales] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [WholeSales] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [WholeSales] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [WholeSales] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [WholeSales] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [WholeSales] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [WholeSales] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [WholeSales] SET RECOVERY FULL 
GO
ALTER DATABASE [WholeSales] SET  MULTI_USER 
GO
ALTER DATABASE [WholeSales] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [WholeSales] SET DB_CHAINING OFF 
GO
ALTER DATABASE [WholeSales] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [WholeSales] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [WholeSales] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [WholeSales] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'WholeSales', N'ON'
GO
ALTER DATABASE [WholeSales] SET QUERY_STORE = OFF
GO
USE [WholeSales]
GO
/****** Object:  User [NamaaAmeen]    Script Date: 1/14/2023 11:03:33 PM ******/
CREATE USER [NamaaAmeen] FOR LOGIN [NamaaAmeen] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [NamaaAmeen]
GO
/****** Object:  Schema [Stock]    Script Date: 1/14/2023 11:03:33 PM ******/
CREATE SCHEMA [Stock]
GO
/****** Object:  UserDefinedFunction [dbo].[Fn_MaxStock]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE  function [dbo].[Fn_MaxStock]

( @stockid  int ) 
 returns int
  as 
  begin 

  declare @ReorderLevel int =dbo.FN_ReOrderLevel(@stockid) ,
   @ReorderQuantity int = dbo.Fn_ReOrderQuantity (@stockid)  ,
   @MinDemand int , @MinLeadTime int , @MaxStock int 
  
  
   select  @MinDemand=  min(orderquantity)  
from ArchivedOrderItems
where StockID = @stockid


  select @MinLeadTime =  min (day (PurchaseEndDate) - day(PurchaseDate) )
  from ArchivedPurchaseItems
  where StockID =@stockid
  group by StockID
   
   set @MaxStock = @ReorderLevel + @ReorderQuantity - (@MinDemand * @MinLeadTime)
   

  return @MaxStock

  end 
GO
/****** Object:  UserDefinedFunction [dbo].[FN_ReorderLevel]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE function [dbo].[FN_ReorderLevel] 

   ( @stockid  int ) 
 returns int
  as 
  begin 

declare @MaxUnitSold int , @MaxLeadTime int  , @ReorderLevel int  

select  @MaxUnitSold= max(orderquantity)  
from ArchivedOrderItems
where StockID = @Stockid


 select @MaxLeadTime = max (day (PurchaseEndDate) - day(PurchaseDate) )
  from ArchivedPurchaseItems
  where StockID =@Stockid
  group by StockID


  set @ReorderLevel = @MaxLeadTime * @MaxUnitSold


    return @ReorderLevel

  end 
GO
/****** Object:  UserDefinedFunction [dbo].[FN_ReOrderPoint]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE  function [dbo].[FN_ReOrderPoint]
  ( @stockID  int ) 
  returns int
  as 
  begin 

  declare @Demand  int  ,
          @LeadTime int ,
          @ReOrderPoint  int ,
		  @WorkDays  int = 25 ,
		  @SafetyStock int  = dbo.FN_SafetyStock (@stockid)

		  select  @Demand = sum (OrderQuantity)
		  from ArchivedOrderItems
		  where @stockID = StockID
		  group by StockID 

		 select  @LeadTime = avg (day (PurchaseEndDate)- day(PurchaseDate) )
         from ArchivedPurchaseItems
         where @stockID = StockID

		 
      
	  set @ReOrderPoint = ( (@Demand/@WorkDays ) *@LeadTime ) +@SafetyStock
		 
	

  return @ReOrderPoint
  end 
GO
/****** Object:  UserDefinedFunction [dbo].[Fn_ReOrderQuantity]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Fn_ReOrderQuantity] 
( @stockid  int ) 
 returns int
  as 
  begin 

  declare  @ReOrderQuantity int ,  @AnnualDemand   int , @CostPerUnit decimal(10,3)  , @HoldingCostPerUnit  decimal(10,3) 

    select @AnnualDemand= sum (OrderQuantity)* 12
	from ArchivedOrderItems
    where StockID =@stockid
    group by StockID 

    select   @CostPerUnit=  avg(UnitCost)
    from suppliersStockDetails a
    inner join suppliersStock b on b.suppliersStockID=a.suppliersStockID
    inner join Stock  s on s.StockID=b.StockiD 
      where s.StockID =@stockid
     group by s.StockID  


   select @HoldingCostPerUnit =HoldingCostPerUnit 
   from WarehouseStock  w
    inner join Stock  s on s.StockID =w.StockID
      where s.StockID =@stockid

	set  @ReOrderQuantity = ceiling ( sqrt ((2 *@AnnualDemand * @CostPerUnit )/ @HoldingCostPerUnit )  )


  return @ReOrderQuantity

  end 
GO
/****** Object:  UserDefinedFunction [dbo].[FN_SafetyStock]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[FN_SafetyStock]
( @Stockid int )
returns int
as
begin

declare @MaxUnitSold int  ,
        @AVGxUnitSold decimal(10,2)  , 
		@MaxLeadTime int ,
		@AVGleadtime decimal(10,2) ,
		@SafetyStock int 


select   @MaxUnitSold= max(orderquantity)  
from ArchivedOrderItems
where StockID = @Stockid

select @AVGxUnitSold=   avg(orderquantity) 
from ArchivedOrderItems
where StockID = @Stockid


  select  @MaxLeadTime = max (day (PurchaseEndDate) - day(PurchaseDate) )
  from ArchivedPurchaseItems
  where StockID =@Stockid
  group by StockID

 

  select @AVGleadtime= avg (day (PurchaseEndDate) - day(PurchaseDate) )
  from ArchivedPurchaseItems
   where StockID = @Stockid
  group by StockID

  
  set @SafetyStock =  (@MaxUnitSold *@MaxLeadTime )  - (@AVGxUnitSold * @AVGleadtime)


  return @SafetyStock 

  end 
GO
/****** Object:  Table [dbo].[ActionType]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActionType](
	[ActionTypeID] [int] IDENTITY(1,1) NOT NULL,
	[ActionTypeDesc] [varchar](50) NOT NULL,
 CONSTRAINT [PK_ActionType] PRIMARY KEY CLUSTERED 
(
	[ActionTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ArchivedOrderItems]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ArchivedOrderItems](
	[OrderItemsID] [int] NOT NULL,
	[OrderID] [int] NULL,
	[StockID] [int] NULL,
	[OrderQuantity] [int] NULL,
	[UnitPrice] [decimal](10, 2) NULL,
	[Discount] [decimal](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ArchivedPurchaseItems]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ArchivedPurchaseItems](
	[PurchaseOrderID] [int] NOT NULL,
	[StockID] [int] NULL,
	[Quantity] [int] NULL,
	[CostPrice] [decimal](10, 2) NULL,
	[TotalCost] [decimal](10, 2) NULL,
	[PurchaseDate] [smalldatetime] NULL,
	[PurchaseEndDate] [smalldatetime] NULL,
	[SupplierID] [int] NULL,
	[IsSend] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AudiTrailLog]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AudiTrailLog](
	[AuditTrailLogID] [int] IDENTITY(1,1) NOT NULL,
	[TransactionDesc] [varchar](max) NOT NULL,
	[UserID] [int] NOT NULL,
	[TransactionDate] [datetime] NOT NULL,
 CONSTRAINT [PK_AudiTrailLog] PRIMARY KEY CLUSTERED 
(
	[AuditTrailLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Brands]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Brands](
	[BrandID] [int] IDENTITY(1,1) NOT NULL,
	[BrandName] [varchar](50) NOT NULL,
	[ISactive] [bit] NOT NULL,
 CONSTRAINT [PK_Brands] PRIMARY KEY CLUSTERED 
(
	[BrandID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Category]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Category](
	[CategoryID] [int] NOT NULL,
	[CategoryName] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_Category] PRIMARY KEY CLUSTERED 
(
	[CategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Customers]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customers](
	[CustomerID] [int] IDENTITY(1,1) NOT NULL,
	[CompanyName] [varchar](40) NULL,
	[Address] [varchar](60) NULL,
	[City] [varchar](15) NULL,
	[Country] [varchar](15) NULL,
	[Phone] [varchar](24) NULL,
	[Email] [varchar](30) NULL,
 CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DataLog]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DataLog](
	[DataLogID] [int] IDENTITY(1,1) NOT NULL,
	[TableName] [varchar](max) NULL,
	[RowID] [int] NULL,
	[OldValue] [varchar](max) NULL,
	[NewValue] [varchar](max) NULL,
	[ActionDate] [datetime] NULL,
	[ActionBy] [int] NULL,
	[ActionTypeID] [int] NULL,
 CONSTRAINT [PK_DataLog] PRIMARY KEY CLUSTERED 
(
	[DataLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Departments]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Departments](
	[DeptID] [int] NOT NULL,
	[DeptName] [varchar](30) NULL,
 CONSTRAINT [PK_Departments] PRIMARY KEY CLUSTERED 
(
	[DeptID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Empolyee]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Empolyee](
	[EmpID] [int] NOT NULL,
	[FirstName] [varchar](40) NULL,
	[LastName] [varchar](40) NULL,
	[DOB] [date] NULL,
	[HireDate] [date] NULL,
	[Address] [varchar](60) NULL,
	[Phone] [varchar](24) NULL,
	[Gender] [char](1) NULL,
	[IsActive] [bit] NULL,
	[DeptID] [int] NULL,
 CONSTRAINT [PK_Empolyee] PRIMARY KEY CLUSTERED 
(
	[EmpID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ErrorLog]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ErrorLog](
	[ErrorLogID] [int] IDENTITY(1,1) NOT NULL,
	[ErrorMessage] [varchar](max) NULL,
	[ErrorLocation] [varchar](max) NULL,
	[ErrorDate] [datetime] NULL,
	[ErrorUser] [int] NULL,
 CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED 
(
	[ErrorLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MaxMinQuantity]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MaxMinQuantity](
	[StockID] [int] NULL,
	[MaxQuantity] [int] NULL,
	[MinQuantity] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[OrderItems]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderItems](
	[OrderItemsID] [int] IDENTITY(1,1) NOT NULL,
	[OrderID] [int] NULL,
	[StockID] [int] NULL,
	[OrderQuantity] [int] NULL,
	[UnitPrice] [decimal](10, 3) NULL,
	[Discount] [decimal](10, 3) NULL,
 CONSTRAINT [PK_OrderItems] PRIMARY KEY CLUSTERED 
(
	[OrderItemsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[OrderPayment]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderPayment](
	[PaymentNumber] [int] NOT NULL,
	[PaymentType] [varchar](40) NULL,
 CONSTRAINT [PK_OrderPayment] PRIMARY KEY CLUSTERED 
(
	[PaymentNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Orders]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Orders](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[OrderDate] [smalldatetime] NULL,
	[CustomerID] [int] NULL,
	[EmployeeID] [int] NULL,
	[PaymentID] [int] NULL,
 CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Payment]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payment](
	[PaymentID] [int] IDENTITY(1,1) NOT NULL,
	[PaymentNumber] [varchar](100) NULL,
	[PaymentDate] [date] NULL,
	[PaymentAmount] [decimal](10, 3) NULL,
	[PaymentStatus] [varchar](30) NULL,
 CONSTRAINT [PK_Payment] PRIMARY KEY CLUSTERED 
(
	[PaymentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PurchaseItems]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PurchaseItems](
	[PurchaseItemsID] [int] IDENTITY(1,1) NOT NULL,
	[StockID] [int] NULL,
	[Quantity] [int] NULL,
	[CostPrice] [decimal](10, 2) NULL,
	[TotalCost] [decimal](10, 2) NULL,
	[PurchaseDate] [smalldatetime] NULL,
	[PurchaseEndDate] [smalldatetime] NULL,
	[SupplierID] [int] NULL,
	[IsSend] [bit] NULL,
 CONSTRAINT [PK_PurchaseOrder] PRIMARY KEY CLUSTERED 
(
	[PurchaseItemsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[purchaseOrder]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[purchaseOrder](
	[PurchaseOrderID] [int] IDENTITY(1,1) NOT NULL,
	[PurchaseOrderAmount] [int] NULL,
	[PurchaseOrderCost] [decimal](10, 3) NULL,
	[SupplierID] [int] NULL,
	[EmpolyeeID] [int] NULL,
	[IsSend] [bit] NULL,
 CONSTRAINT [PK_purchaseOrder_1] PRIMARY KEY CLUSTERED 
(
	[PurchaseOrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Shipments]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Shipments](
	[ShipID] [int] IDENTITY(1,1) NOT NULL,
	[OrderID] [int] NULL,
	[TotalPrice] [decimal](10, 2) NULL,
	[ShipNo] [varchar](40) NULL,
	[ShipDate] [smalldatetime] NULL,
	[ShipAddress] [varchar](60) NULL,
	[ShipCity] [varchar](15) NULL,
	[ShipCountry] [varchar](15) NULL,
	[ContactPhone] [char](24) NULL,
 CONSTRAINT [PK_Shipments] PRIMARY KEY CLUSTERED 
(
	[ShipID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Stock]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Stock](
	[StockID] [int] IDENTITY(1,1) NOT NULL,
	[StockName] [varchar](50) NOT NULL,
	[BrandID] [int] NOT NULL,
	[CategoryID] [int] NOT NULL,
	[UnitPrice] [decimal](10, 2) NOT NULL,
	[QuantityInStock] [int] NULL,
	[ReOrderPoint] [int] NULL,
	[ReOrderQuantity] [int] NULL,
	[StockOnOrder] [int] NULL,
	[StockSize] [varchar](10) NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_Stock_1] PRIMARY KEY CLUSTERED 
(
	[StockID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[suppliers]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[suppliers](
	[SupplierID] [int] NOT NULL,
	[CompanyName] [varchar](40) NULL,
	[ContactName] [varchar](30) NULL,
	[Address] [varchar](60) NULL,
	[City] [varchar](15) NULL,
	[Country] [varchar](15) NULL,
	[Phone] [varchar](24) NULL,
	[Email] [varchar](30) NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_suppliers] PRIMARY KEY CLUSTERED 
(
	[SupplierID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[suppliersStock]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[suppliersStock](
	[suppliersStockID] [int] NOT NULL,
	[SupplierID] [int] NULL,
	[StockiD] [int] NULL,
 CONSTRAINT [PK_suppliersStock] PRIMARY KEY CLUSTERED 
(
	[suppliersStockID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[suppliersStockDetails]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[suppliersStockDetails](
	[suppliersStockID] [int] NULL,
	[SupplierStock] [int] NULL,
	[UnitCost] [decimal](10, 3) NULL,
	[WorkDays] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Warehouses]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Warehouses](
	[WarehouseID] [int] NOT NULL,
	[WarehouseName] [varchar](40) NULL,
	[address] [varchar](60) NULL,
	[WareHouseSpace] [varchar](20) NULL,
 CONSTRAINT [PK_Warehouses] PRIMARY KEY CLUSTERED 
(
	[WarehouseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WarehouseStock]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WarehouseStock](
	[WarehouseID] [int] NOT NULL,
	[StockID] [int] NOT NULL,
	[HoldingCostPerUnit] [decimal](10, 3) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DataLog]  WITH CHECK ADD  CONSTRAINT [FK_DataLog_ActionType] FOREIGN KEY([ActionTypeID])
REFERENCES [dbo].[ActionType] ([ActionTypeID])
GO
ALTER TABLE [dbo].[DataLog] CHECK CONSTRAINT [FK_DataLog_ActionType]
GO
ALTER TABLE [dbo].[Empolyee]  WITH CHECK ADD  CONSTRAINT [FK_Empolyee_Empolyee] FOREIGN KEY([DeptID])
REFERENCES [dbo].[Departments] ([DeptID])
GO
ALTER TABLE [dbo].[Empolyee] CHECK CONSTRAINT [FK_Empolyee_Empolyee]
GO
ALTER TABLE [dbo].[MaxMinQuantity]  WITH CHECK ADD  CONSTRAINT [FK_MaxMinQuantity_Stock] FOREIGN KEY([StockID])
REFERENCES [dbo].[Stock] ([StockID])
GO
ALTER TABLE [dbo].[MaxMinQuantity] CHECK CONSTRAINT [FK_MaxMinQuantity_Stock]
GO
ALTER TABLE [dbo].[OrderItems]  WITH CHECK ADD  CONSTRAINT [FK_OrderItems_Orders1] FOREIGN KEY([OrderID])
REFERENCES [dbo].[Orders] ([OrderID])
GO
ALTER TABLE [dbo].[OrderItems] CHECK CONSTRAINT [FK_OrderItems_Orders1]
GO
ALTER TABLE [dbo].[OrderItems]  WITH CHECK ADD  CONSTRAINT [FK_OrderItems_Stock] FOREIGN KEY([StockID])
REFERENCES [dbo].[Stock] ([StockID])
GO
ALTER TABLE [dbo].[OrderItems] CHECK CONSTRAINT [FK_OrderItems_Stock]
GO
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Customers] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customers] ([CustomerID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_Customers]
GO
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Empolyee] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Empolyee] ([EmpID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_Empolyee]
GO
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Payment] FOREIGN KEY([PaymentID])
REFERENCES [dbo].[Payment] ([PaymentID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_Payment]
GO
ALTER TABLE [dbo].[purchaseOrder]  WITH CHECK ADD  CONSTRAINT [FK_purchaseOrder_suppliers1] FOREIGN KEY([SupplierID])
REFERENCES [dbo].[suppliers] ([SupplierID])
GO
ALTER TABLE [dbo].[purchaseOrder] CHECK CONSTRAINT [FK_purchaseOrder_suppliers1]
GO
ALTER TABLE [dbo].[Shipments]  WITH CHECK ADD  CONSTRAINT [FK_Shipments_Orders] FOREIGN KEY([OrderID])
REFERENCES [dbo].[Orders] ([OrderID])
GO
ALTER TABLE [dbo].[Shipments] CHECK CONSTRAINT [FK_Shipments_Orders]
GO
ALTER TABLE [dbo].[suppliersStock]  WITH CHECK ADD  CONSTRAINT [FK_suppliersStock_Stock] FOREIGN KEY([StockiD])
REFERENCES [dbo].[Stock] ([StockID])
GO
ALTER TABLE [dbo].[suppliersStock] CHECK CONSTRAINT [FK_suppliersStock_Stock]
GO
ALTER TABLE [dbo].[suppliersStock]  WITH CHECK ADD  CONSTRAINT [FK_suppliersStock_suppliers] FOREIGN KEY([SupplierID])
REFERENCES [dbo].[suppliers] ([SupplierID])
GO
ALTER TABLE [dbo].[suppliersStock] CHECK CONSTRAINT [FK_suppliersStock_suppliers]
GO
ALTER TABLE [dbo].[suppliersStockDetails]  WITH CHECK ADD  CONSTRAINT [FK_suppliersStockDetails_suppliersStock] FOREIGN KEY([suppliersStockID])
REFERENCES [dbo].[suppliersStock] ([suppliersStockID])
GO
ALTER TABLE [dbo].[suppliersStockDetails] CHECK CONSTRAINT [FK_suppliersStockDetails_suppliersStock]
GO
ALTER TABLE [dbo].[Empolyee]  WITH CHECK ADD  CONSTRAINT [CHK_Student] CHECK  (([Gender]='M' OR [Gender]='F'))
GO
ALTER TABLE [dbo].[Empolyee] CHECK CONSTRAINT [CHK_Student]
GO
/****** Object:  StoredProcedure [dbo].[SP_ArchivedPurchaseOrders]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_ArchivedPurchaseOrders]

as
begin
 
insert into ArchivedPurchaseItems
( PurchaseOrderID , StockID, Quantity, CostPrice, TotalCost, PurchaseDate, PurchaseEndDate , SupplierID ,IsSend )
select  PurchaseItemsID , StockID , Quantity , CostPrice , TotalCost , PurchaseDate , PurchaseEndDate , SupplierID  , IsSend
from PurchaseItems


delete  from OrderItems

end 
GO
/****** Object:  StoredProcedure [dbo].[SP_ArchiveOrderItems]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure [dbo].[SP_ArchiveOrderItems] 

as
begin

insert into ArchivedOrderItems
( OrderItemsID , OrderID , StockID , OrderQuantity , UnitPrice , Discount )
select  OrderItemsID , OrderID , StockID , OrderQuantity , UnitPrice , Discount
from OrderItems


delete  from OrderItems

end 
GO
/****** Object:  StoredProcedure [dbo].[Sp_GetBest2Customers]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE procedure [dbo].[Sp_GetBest2Customers]
 as
 begin 

 select   tbl.CompanyName   ,  Address , City , Country , Phone , Email
 from 
 (
 select c.CustomerID , CompanyName ,  sum (OrderQuantity * UnitPrice ) as total  , Address , City , Country , Phone , Email
 from Customers C 
 inner join Orders O on o.CustomerID = c.CustomerID 
 inner join OrderItems os on os.OrderID = o.OrderID
   group by c.CustomerID , CompanyName , Address , City , Country , Phone , Email
 having sum (OrderQuantity * UnitPrice )  in( select top 2  with ties sum (OrderQuantity * UnitPrice )
 from OrderItems group by OrderID order by 1 desc )
 ) tbl 
 
 end 
GO
/****** Object:  StoredProcedure [dbo].[Sp_GetBest2Suppliers]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_GetBest2Suppliers]
  as
  begin

  select  SupplierID,tbl.CompanyName  ,  ContactName , Address , City , Country , Phone
  from (
  select ss. SupplierID ,CompanyName  ,sum ( QuantityInStock ) quantity  , ContactName , Address , City , Country , Phone 
  from suppliersStock ss 
  inner join suppliers s on s.SupplierID = ss.SupplierID
  inner join Stock o on o.StockID = ss.StockiD
  group by ss. SupplierID  , CompanyName , ContactName , Address , City , Country , Phone
  having sum ( QuantityInStock ) in (select  top 2 with ties  sum ( QuantityInStock ) from Stock s  inner join suppliersStock ss on ss.StockiD = s.StockID 
  inner join suppliers p on p.SupplierID = ss.SupplierID   group  by  ss.SupplierID order by 1 desc ) ) tbl 


 end
GO
/****** Object:  StoredProcedure [dbo].[SP_GetCountOfSalesAndProfitOnYearForEachBrand]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE procedure [dbo].[SP_GetCountOfSalesAndProfitOnYearForEachBrand] 

  @brandid int  

  as
  begin 

  select b.BrandID  , year(OrderDate) [Year]  , count  (OrderQuantity)  [Count Of Sales ] ,   sum ((a.UnitPrice-tbl.unitcost) * OrderQuantity) netprofit 

  from OrderItems a
  inner join Orders aa on aa.OrderID =a.OrderID
  inner join Stock  b on b.StockID= a.StockID 
  inner join Brands c on c.BrandID = b.BrandID
  inner join 
  (  select avg (UnitCost) unitcost  , StockiD   from suppliersStock s
  inner join suppliersStockDetails ss on ss.suppliersStockID=s.suppliersStockID group by StockiD ) tbl 
  on tbl.StockiD = b.StockID
      where b.BrandID = @brandid

  group by b.BrandID ,  year(OrderDate)
  

  end 
GO
/****** Object:  StoredProcedure [dbo].[SP_GetQuantityStockByeachBrand]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure  [dbo].[SP_GetQuantityStockByeachBrand] 
 @BrandId int
 as
 begin 


 select b.BrandID  , BrandName ,sum ( QuantityInStock ) QuantityInStock 
 from Stock s 
 inner join Brands B on b.BrandID = s.BrandID
     where b.BrandID = @BrandId
  group by  b.BrandID , BrandName
 

  end 
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewBrand]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_InsertNewBrand]
@BrandName varchar(30) , 
@IsActive bit 

as
begin 

insert into Brands
( BrandName , ISactive ) 
values 
( @BrandName , 1)
end
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewCategory]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[SP_InsertNewCategory]
@CategoryName varchar(30) , 
@IsActive bit 

as
begin 

insert into Category
( CategoryName , ISactive ) 
values 
( @CategoryName, 1)
end
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewCustomers]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  create procedure  [dbo].[SP_InsertNewCustomers] 
 
  @CompanyName int , 
  @Address varchar(60) , 
  @City varchar(30)  ,
  @Country  varchar(30)  ,
  @Phone varchar(24) , 
  @Email varchar(30 ) 

  as 
  begin

  Insert into Customers
  ( CompanyName , [Address], City , Country , Phone , Email ) 
  values 
  ( @CompanyName , @Address, @City , @Country , @Phone , @Email ) 


  end 
GO
/****** Object:  StoredProcedure [dbo].[Sp_InsertNewEmpolyee]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_InsertNewEmpolyee] 
 @firstName varchar(30)  , 
 @LastName varchar(30) , 
 @DOB date , 
 @HireDate date , 
 @address varchar(60) , 
 @Phone varchar(24) ,
 @Gender char(1) ,
 @IsActive bit 

 as
 begin 

insert into Empolyee
(FirstName,LastName,DOB,HireDate,[Address],Phone  , Gender  , IsActive )
values 
(@firstName,@LastName , @DOB , @HireDate , @address , @Phone , @Gender , 1 ) 

end
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewOrder]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_InsertNewOrder] 


@CustomerID  int , 
@EmployeeID int 

--@StockID int ,
--@OrderQuantity int , 
--@Discount decimal (10,3)  

--@ShipNO varchar(30) , 
--@shipaddress varchar(60) ,
--@ShipCity  varchar(40) ,
--@ShipCountry  varchar(40)  

as 
begin



--declare @unitprice decimal (10,3)  

--select @unitprice = UnitPrice
--from Stock 
--where StockID = @StockID



insert into orders 
( OrderDate ,CustomerID ,EmployeeID      )
values 
(  getdate() , @CustomerID , @EmployeeID  )

--insert into OrderItems 
--(OrderID , StockID , OrderQuantity , UnitPrice , Discount )
--values
--   (IDENT_CURRENT ( 'Order' ), @StockId , @OrderQuantity  , @unitprice , @Discount )

 --insert into Shipments
 --( OrderID , TotalPrice, ShipNo , ShipDate , ShipAddress , ShipCity , ShipCountry)
 --values 
 --(IDENT_CURRENT ( 'Order' ) , 0 , @ShipNO ,  getdate() , @shipaddress , @ShipCity , @ShipCountry ) 

       end
GO
/****** Object:  StoredProcedure [dbo].[Sp_InsertNewShipment]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_InsertNewShipment] 

@orderid int ,
@ShipNO varchar(30) , 
@shipaddress varchar(60) ,
@ShipCity  varchar(40) ,
@ShipCountry  varchar(40)  

as
begin

declare @TotalPrice decimal (10,3) 

select  @TotalPrice = OrderQuantity * UnitPrice * Discount
from OrderItems 
where orderid= @orderid

 insert into Shipments
 ( OrderID , TotalPrice, ShipNo , ShipDate , ShipAddress , ShipCity , ShipCountry)
 values 
 (@orderid  ,@TotalPrice,@ShipNO ,  getdate() , @shipaddress , @ShipCity , @ShipCountry ) 

end 
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewStock]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_InsertNewStock] 


@StockName varchar(40)  ,
@BrandID int  , 
@CategoryID int , 
@UnitPrice decimal (10,3) , 
@stocksize varchar(20) ,
@IsActive bit 


as
begin 

--declare  @reprderlevel int  , @reorderquantity int 

----set @reprderlevel = dbo.FN_ReOrderLevel (@@IDENTITY)
---- set @reorderquantity = dbo.Fn_ReOrderQuantity (@@IDENTITY ) 

Insert into Stock 
( StockName , BrandID ,CategoryID , UnitPrice, QuantityInStock ,  ReOrderPoint , ReOrderQuantity , StockOnOrder,StockSize ,IsActive)
values 
( @StockName , @BrandID , @CategoryID , @UnitPrice , '' , ''  ,'' ,0,  @stocksize ,  1)

 end 
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewSuppliers]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 create procedure [dbo].[SP_InsertNewSuppliers]

 @companyName varchar(30)  ,
 @contactName varchar(30) ,
 @address varchar(60) , 
 @city  varchar(30) , 
 @Country  varchar(30)  ,
 @Phone varchar(24) , 
 @Email varchar(30 )  , 
 @IsActive bit 


 as
 begin
 insert into suppliers
 ( CompanyName , ContactName , [Address] , City , Country , Phone , Email , IsActive ) 
 values 
 ( @CompanyName , @contactName , @address , @city , @Country , @Phone , @Email , 1 ) 


 end 
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewWarehouses]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_InsertNewWarehouses]
@WarehouseName varchar(30) , 
@address varchar(60) , 
@WareHouseSpace varchar(20) 

as
begin 

insert into Warehouses
( WarehouseName , [address] , WareHouseSpace ) 
values 
( @WarehouseName , @address , @WareHouseSpace ) 
end
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertNewWarehouseStock]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_InsertNewWarehouseStock]
@WarehouseId INT , 
@StockID INT  
 

as
begin 

declare @holdingcostperunit  decimal(10 ,3) 

  select  @holdingcostperunit = avg (UnitCost ) * 0.25
    from suppliersStockDetails a
    inner join suppliersStock b on b.suppliersStockID=a.suppliersStockID 
	where StockiD = @StockID
	group by StockiD
	
    
insert into WarehouseStock
( WarehouseID , StockID , HoldingCostPerUnit ) 
values 
( @WarehouseId , @StockID , @holdingcostperunit ) 
end
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertOrderItems]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_InsertOrderItems]  
                           
@orderid int , 
@StockID int ,
@OrderQuantity int ,
@EmpolyeeID int  ,
@ErrorMessage varchar(max)  out 

as 
begin 
begin transaction 
begin try


declare @unitprice decimal (10,3)   ,
         @Discount decimal (10, 3 )  ,
		 @quantityInStock int , 
		 @MaxQ int , 
		 @MinQ int 

    select @unitprice = UnitPrice
    from Stock 
     where StockID = @StockID

    select @quantityInStock = QuantityInStock 
    from Stock 
    where StockID = @StockID


	select  @maxQ = MaxQuantity
	from MaxMinQuantity 
	where StockID = @StockID 

	select  @MinQ = MinQuantity
	from MaxMinQuantity 
	where StockID = @StockID

if  (@OrderQuantity >=150 )  
begin  
set @Discount = 0.05 
end 
else 
begin 
set @Discount = 0 
end 

if @OrderQuantity >= @MaxQ  
begin 
print 'More than max quantity' 

end 

else if  @OrderQuantity <= @MinQ
begin
print  'Less than min quantity' 

end 

else  
begin 

insert into OrderItems 
(OrderID , StockID , OrderQuantity , UnitPrice , Discount  )
values
   (@orderid, @StockId , @OrderQuantity  , @unitprice , @Discount  )

insert into DataLog
 (TableName,RowId,OldValue,NewValue,ActionDate,ActionTypeID,ActionBy)
select 
 'stock' , StockID ,  'QuantityInStock:' +cast( QuantityInStock as varchar(50) ) + 'StockOnOrder:' +cast( StockOnOrder as varchar(50) ), 
 'QuantityInStock:' +cast( QuantityInStock-@OrderQuantity as varchar(50) ) + 'StockOnOrder:' +cast( (StockOnOrder + @OrderQuantity) as varchar(50) )    , 
  getdate() ,2 ,  @EmpolyeeID
  from stock 
 where stockid= @StockID


  insert into AudiTrailLog
  (TransactionDesc, UserID , TransactionDate) 
  values 
  ( 'update in  table stock  with id :' +  cast ( @StockID as varchar (50)) , @EmpolyeeID , getdate() ) 
   
      update Stock
   set QuantityInStock = QuantityInStock-@OrderQuantity ,
        StockOnOrder = StockOnOrder + @OrderQuantity
		where StockID= @StockID

   end     

  commit transaction 
  end try 
   begin catch 
      rollback ; 
	    insert into ErrorLog 
	   ( ErrorMessage,ErrorLocation,ErrorDate,ErrorUser ) 
	   values 
	   ( ERROR_MESSAGE() , ERROR_PROCEDURE()  , GETDATE() , @EmpolyeeID) 
	      set @ErrorMessage= ERROR_MESSAGE () ; 
        end catch 
end 
GO
/****** Object:  StoredProcedure [dbo].[SP_InsertSupplierStockDetails]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_InsertSupplierStockDetails] 
@SuppliersStockID  int ,
@supplierStock int , 
@UnitCost decimal (10,3)  , 
@Workdays int 


as 
begin

insert into suppliersStockDetails
( suppliersStockID ,SupplierStock , UnitCost , WorkDays )
values 
( @SuppliersStockID , @supplierStock , @UnitCost , @Workdays )

end
GO
/****** Object:  StoredProcedure [dbo].[SP_Payment]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Payment] 
@paymentNumber varchar(60) ,
@PaymentAmount varchar(max) ,
@PaymentStatus varchar(30) 

as
begin
insert into Payment
(paymentnumber ,PaymentDate ,PaymentAmount, PaymentStatus )
values 
( @paymentNumber , GETDATE () , @PaymentAmount , @PaymentStatus ) 

end
GO
/****** Object:  StoredProcedure [dbo].[SP_PurchaseOrder]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE  procedure [dbo].[SP_PurchaseOrder] 

    @EmpolyeeID int , 
	@isSend bit ,
	@supplierid int , 
	@ErrorMessage varchar(max)  out 

	
	as 
begin 
begin transaction 
begin try

	declare @PurchaseOrderAmount int  , @PurchaseOrderCost decimal   , @supplierid2 int  , @issend2 bit


	select @issend2  =IsSend
	from PurchaseItems
		where SupplierID = @supplierid


	select  @PurchaseOrderAmount =  sum(Quantity)  
	from PurchaseItems
	where SupplierID = @supplierid and  IsSend = 0 


	select  @PurchaseOrderCost = sum (TotalCost)
	from PurchaseItems
	where SupplierID = @supplierid and  IsSend = 0 

	
	if @supplierid=
	(select   distinct SupplierID  
	from PurchaseItems
	where SupplierID = @supplierid) 

	insert into purchaseOrder
	( PurchaseOrderAmount , PurchaseOrderCost,SupplierID,EmpolyeeID  , IsSend )
	values 
	( @PurchaseOrderAmount , @PurchaseOrderCost  , @supplierid  , @EmpolyeeID , @isSend )

   update   purchaseitems
    set IsSend = 1 
   where supplierid= @supplierid 
	


  commit transaction 
  end try 
   begin catch 
      rollback ; 
	    insert into ErrorLog 
	   ( ErrorMessage,ErrorLocation,ErrorDate,ErrorUser ) 
	   values 
	   ( ERROR_MESSAGE() , ERROR_PROCEDURE()  , GETDATE() , @EmpolyeeID) 
	      set @ErrorMessage= ERROR_MESSAGE () ; 
        end catch 
end 
GO
/****** Object:  StoredProcedure [dbo].[SP_UpdatePurshace]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdatePurshace]

     @PurchaseOrderID int  ,
	 @PurchaseEndDate date 

	 as
	 begin 

	 update PurchaseItems
	 set PurchaseEndDate =@PurchaseEndDate
	 where PurchaseItemsID= @PurchaseOrderID

	 end 
GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateStock]    Script Date: 1/14/2023 11:03:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_UpdateStock] 
@unitPrice  decimal(10,3 ) , 
@QuantityInStock int  ,
@StockId int 

as
begin 


update Stock 
set 
	 UnitPrice  = isnull ( @unitPrice ,UnitPrice )  ,
	 QuantityInStock = isnull(@QuantityInStock  , QuantityInStock ) 

       where StockID = @StockID

end 
GO
USE [master]
GO
ALTER DATABASE [WholeSales] SET  READ_WRITE 
GO
