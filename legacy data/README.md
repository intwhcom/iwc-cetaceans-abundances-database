# Abundance Estimates Database - Legacy data

![Status](https://img.shields.io/badge/status-active-brightgreen)
![Version](https://img.shields.io/badge/version-1.0-blue)

This repository contains abundance estimate data for marine species, organised in a legacy Excel-based structure.

---

## 📁 Data Structure

The main dataset consists of **three Excel files**, split by geographic region:

| File | Region |
|------|--------|
| `NA-abundances.xlsx` | North Atlantic |
| `NP-abundances.xlsx` | North Pacific |
| `SH-abundances.xlsx` | Southern Hemisphere |

---

## 📊 Worksheet Organization

### Species Tabs
- Most worksheets represent **individual species**
- Species with sparse data are grouped into **"Other"** tabs
- Small cetacean records migrated from a previous legacy file are either:
  - Stored in **"SM"** (Small Cetacean) tabs, or
  - Given their own species tab when sufficient records exist

> ⚠️ **Note:** Migration of small cetacean data is a **work in progress**.

### Supporting Tabs
The Excel files also contain additional worksheets for:
- 📈 **Full time series** – linked to certain records
- 📚 **References** – source documentation
- 🧮 **Combined abundance calculations** – aggregating strata from the same survey or other scientific committee requests

---

## 📝 Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/your-repo-name.git
