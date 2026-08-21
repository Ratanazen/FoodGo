import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

function Home() {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <div className="flex-shrink-0 flex items-center">
              <span className="text-2xl font-bold text-rose-600">FoodGo</span>
            </div>
            <div className="flex items-center space-x-4">
              <button className="text-gray-600 hover:text-gray-900 font-medium">Log in</button>
              <button className="bg-rose-600 text-white px-4 py-2 rounded-full font-medium hover:bg-rose-700 transition-colors">Sign up</button>
            </div>
          </div>
        </div>
      </header>

      <main>
        {/* Hero Section */}
        <section className="bg-rose-50 py-16 sm:py-24">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <h1 className="text-4xl font-extrabold text-gray-900 sm:text-5xl md:text-6xl">
              It's the food you love, delivered
            </h1>
            <div className="mt-8 max-w-xl mx-auto sm:flex sm:justify-center">
              <div className="relative rounded-md shadow-sm flex-1">
                <input
                  type="text"
                  className="focus:ring-rose-500 focus:border-rose-500 block w-full pl-4 pr-12 sm:text-lg border-gray-300 rounded-full py-4"
                  placeholder="Enter your delivery address"
                />
                <button className="absolute inset-y-0 right-0 px-6 py-4 bg-rose-600 text-white rounded-r-full hover:bg-rose-700 font-medium transition-colors">
                  Find Food
                </button>
              </div>
            </div>
          </div>
        </section>
        
        {/* Features / Content placeholder */}
        <section className="py-12 bg-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-6">Popular Restaurants Near You</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
               {[1,2,3,4,5,6].map(i => (
                 <div key={i} className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow cursor-pointer">
                    <div className="h-48 bg-gray-200 animate-pulse"></div>
                    <div className="p-4">
                      <div className="h-6 bg-gray-200 rounded w-3/4 mb-2 animate-pulse"></div>
                      <div className="h-4 bg-gray-200 rounded w-1/2 animate-pulse"></div>
                    </div>
                 </div>
               ))}
            </div>
          </div>
        </section>
      </main>
    </div>
  );
}

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
      </Routes>
    </Router>
  );
}

export default App;
