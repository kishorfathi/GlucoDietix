"""
Sri Lankan Food Composition Database Importer
This script helps import data from foodcompositiondb.lk into your Supabase database.

Requirements:
    pip install requests beautifulsoup4 supabase
"""

import requests
from bs4 import BeautifulSoup  # type: ignore
import json
import csv
from typing import Dict, List, Optional

class FoodDBImporter:
    """Import food data from foodcompositiondb.lk"""
    
    def __init__(self, base_url: str = "https://www.foodcompositiondb.lk"):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
    
    def search_food(self, query: str) -> List[Dict]:
        """
        Search for foods on the website
        
        Args:
            query: Food name to search
            
        Returns:
            List of food items with their data
        """
        search_url = f"{self.base_url}/search"
        
        try:
            response = self.session.get(search_url, params={'q': query})
            response.raise_for_status()
            
            # Parse the response
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract food items (this will depend on the website structure)
            # You'll need to inspect the HTML structure to implement this
            foods = []
            
            # Placeholder - implement based on actual website structure
            print(f"Search results HTML structure needs to be inspected")
            
            return foods
            
        except requests.RequestException as e:
            print(f"Error searching: {e}")
            return []
    
    def get_food_details(self, food_id: str) -> Optional[Dict]:
        """
        Get detailed information about a specific food item
        
        Args:
            food_id: The ID of the food item
            
        Returns:
            Dictionary with food details
        """
        detail_url = f"{self.base_url}/food/{food_id}"
        
        try:
            response = self.session.get(detail_url)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Parse food details
            # This structure needs to be determined by inspecting the website
            food_data = {}
            
            return food_data
            
        except requests.RequestException as e:
            print(f"Error fetching details: {e}")
            return None
    
    def export_to_csv(self, foods: List[Dict], filename: str):
        """Export foods to CSV format"""
        if not foods:
            print("No foods to export")
            return
        
        keys = foods[0].keys()
        
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=keys)
            writer.writeheader()
            writer.writerows(foods)
        
        print(f"Exported {len(foods)} foods to {filename}")
    
    def export_to_sql(self, foods: List[Dict], filename: str):
        """Export foods to SQL INSERT statements"""
        with open(filename, 'w', encoding='utf-8') as f:
            f.write("-- Generated SQL Inserts from foodcompositiondb.lk\n\n")
            
            for food in foods:
                # Generate INSERT statement
                columns = ', '.join(food.keys())
                values = ', '.join([f"'{v}'" if isinstance(v, str) else str(v) 
                                  for v in food.values()])
                
                sql = f"INSERT INTO foods ({columns}) VALUES ({values});\n"
                f.write(sql)
        
        print(f"Exported {len(foods)} foods to {filename}")


class ManualFoodEntry:
    """Helper class for manually entering food data"""
    
    @staticmethod
    def create_food_dict(
        name: str,
        name_sinhala: str,
        name_tamil: str,
        category: str,
        sub_category: str,
        carbs_100g: float,
        protein_100g: float,
        fat_100g: float,
        fiber_100g: float,
        energy_kcal: float,
        **kwargs
    ) -> Dict:
        """
        Create a properly formatted food dictionary
        
        Required fields:
            name, category, carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal
            
        Optional fields (pass as **kwargs):
            calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg, thiamin_mg,
            riboflavin_mg, niacin_mg, glycemic_index, glycemic_load,
            cholesterol_mg, sodium_mg, potassium_mg, edible_portion_percent,
            water_content_percent, serving_size_g, is_local, source
        """
        
        food = {
            'name': name,
            'name_sinhala': name_sinhala,
            'name_tamil': name_tamil,
            'category': category,
            'sub_category': sub_category,
            'carbs_100g': carbs_100g,
            'protein_100g': protein_100g,
            'fat_100g': fat_100g,
            'fiber_100g': fiber_100g,
            'energy_kcal': energy_kcal,
        }
        
        # Add optional fields
        optional_fields = [
            'calcium_mg', 'iron_mg', 'vitamin_a_mcg', 'vitamin_c_mg',
            'thiamin_mg', 'riboflavin_mg', 'niacin_mg', 'glycemic_index',
            'glycemic_load', 'cholesterol_mg', 'sodium_mg', 'potassium_mg',
            'edible_portion_percent', 'water_content_percent', 'serving_size_g',
            'is_local', 'source'
        ]
        
        for field in optional_fields:
            if field in kwargs:
                food[field] = kwargs[field]
        
        return food
    
    @staticmethod
    def generate_sql_insert(food: Dict) -> str:
        """Generate SQL INSERT statement for a food item"""
        
        columns = []
        values = []
        
        for key, value in food.items():
            columns.append(key)
            if value is None:
                values.append('NULL')
            elif isinstance(value, str):
                # Escape single quotes in strings
                escaped_value = value.replace("'", "''")
                values.append(f"'{escaped_value}'")
            elif isinstance(value, bool):
                values.append('true' if value else 'false')
            else:
                values.append(str(value))
        
        sql = f"INSERT INTO foods ({', '.join(columns)}) VALUES ({', '.join(values)});"
        return sql


def example_manual_entry():
    """Example of manually entering food data"""
    
    # Create a food item
    food = ManualFoodEntry.create_food_dict(
        name='Kottu Roti',
        name_sinhala='කොත්තු රොටි',
        name_tamil='கொத்து ரொட்டி',
        category='Main Dishes',
        sub_category='Street Food',
        carbs_100g=22.5,
        protein_100g=8.5,
        fat_100g=12.0,
        fiber_100g=2.5,
        energy_kcal=245,
        calcium_mg=35,
        iron_mg=2.2,
        vitamin_a_mcg=45,
        vitamin_c_mg=8,
        water_content_percent=55.0,
        serving_size_g=250,
        is_local=True,
        source='foodcompositiondb.lk'
    )
    
    # Generate SQL
    sql = ManualFoodEntry.generate_sql_insert(food)
    print(sql)
    
    return food


if __name__ == "__main__":
    print("Sri Lankan Food Database Importer")
    print("=" * 50)
    print()
    print("Options:")
    print("1. Use the comprehensive seed_data.sql file (RECOMMENDED)")
    print("2. Manually add foods using ManualFoodEntry class")
    print("3. Web scraping (requires website structure inspection)")
    print()
    print("For most uses, run the seed_data.sql file in your Supabase SQL editor.")
    print()
    
    # Example of manual entry
    print("Example - Creating a food item manually:")
    print("-" * 50)
    example_manual_entry()
