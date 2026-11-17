# Dataset de Juice Corner BD

Este directorio almacena el conjunto de datos de la base de datos relacional transaccional (TPS / OLTP) de pedidos y entrega de comida de **Juice Corner BD**.

---

## 1. Origen de los Datos

El dataset base proviene del repositorio abierto de Kaggle:
- **Identificador Kaggle:** [`thesohanur/restaurant-and-food-delivery-relational-database`](https://www.kaggle.com/datasets/thesohanur/restaurant-and-food-delivery-relational-database)

Para descargar o actualizar los datos automáticamente vía Python:
```bash
pip install kagglehub
python download_kaggle_dataset.py
```

---

## 2. Política de Repositorio (Archivos Pesados / Large Files)

> [!NOTE]
> Debido a que varios archivos CSV individuales superan los límites de GitHub (por ejemplo, `order_status_history.csv` con ~503 MB y `orders.csv` con ~255 MB, sumando más de 1.2 GB en total), los archivos `.csv` y `.zip` se encuentran ignorados en el archivo `.gitignore` del proyecto.

Para cargar los datos en SQL Server una vez descargados los CSV:
- Utiliza el pipeline automatizado en PowerShell [`Cargar_Datos_OLTP.ps1`](../Cargar_Datos_OLTP.ps1) o el lanzador [`Ejecutar_Carga.bat`](../Ejecutar_Carga.bat).

---

## 3. Carga Automática en SQL Server

Una vez descargados los archivos `.csv` en esta carpeta `dataset/`, ejecuta:
```cmd
Ejecutar_Carga.bat
```
El script de PowerShell (`Cargar_Datos_OLTP.ps1`) utiliza .NET `SqlBulkCopy` con streaming y conversión tipada para cargar las 19 tablas en pocos segundos sin desbordar memoria.
